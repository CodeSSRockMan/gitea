#!/bin/bash
set -e

# ---------- CONFIGURATION ----------
REGION="us-east-1"
MASTER_TAG="jenkins-master"
AGENT_TAG="jenkins-agent-ephemeral"
AGENT_ROLE_NAME="jenkins-agent-role"
AGENT_PROFILE_NAME="jenkins-agent-profile"
AGENT_SG_NAME="jenkins-agent-sg"

DOCKER_HUB_USER="hescobarsanchez"
IMAGE_NAME="ansible-aws-gcp"
IMAGE_TAG="latest"
IMAGE_REF="${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

# ---------- FETCH MASTER INFO ----------
echo "[INFO] Fetching Jenkins Master info..."
INSTANCE_ID=$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Name,Values=$MASTER_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

[[ "$INSTANCE_ID" == "None" || -z "$INSTANCE_ID" ]] && {
  echo "[ERROR] Jenkins Master not found."; exit 1; }

AMI_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].ImageId" --output text)
SUBNET_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].SubnetId" --output text)
VPC_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].VpcId" --output text)

echo "[INFO] Master details: AMI=$AMI_ID, SUBNET=$SUBNET_ID, VPC=$VPC_ID"

# ---------- SECURITY GROUP ----------
echo "[INFO] Checking agent Security Group..."
AGENT_SG_ID=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=$AGENT_SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [[ "$AGENT_SG_ID" == "None" || -z "$AGENT_SG_ID" ]]; then
  echo "[INFO] Creating new Security Group..."
  AGENT_SG_ID=$(aws ec2 create-security-group --region "$REGION" \
    --group-name "$AGENT_SG_NAME" --description "Jenkins Agent SG" --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)

  aws ec2 authorize-security-group-egress --region "$REGION" \
    --group-id "$AGENT_SG_ID" --protocol -1 --cidr 0.0.0.0/0 \
    2>/dev/null || echo "[WARN] Egress rule may already exist."
else
  echo "[INFO] Using existing Security Group: $AGENT_SG_ID"
fi

# ---------- IAM ROLE & INSTANCE PROFILE ----------
echo "[INFO] Verifying IAM role and instance profile..."
aws iam get-role --role-name "$AGENT_ROLE_NAME" > /dev/null 2>&1 || {
  echo "[INFO] Creating IAM role..."
  aws iam create-role --role-name "$AGENT_ROLE_NAME" \
    --assume-role-policy-document file://<(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow", "Principal": { "Service": "ec2.amazonaws.com" }, "Action": "sts:AssumeRole" }]
}
EOF
) > /dev/null
}

aws iam attach-role-policy --role-name "$AGENT_ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore > /dev/null || true

aws iam get-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" > /dev/null 2>&1 || {
  echo "[INFO] Creating instance profile..."
  aws iam create-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" > /dev/null
  sleep 5
}

aws iam add-role-to-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" \
  --role-name "$AGENT_ROLE_NAME" > /dev/null 2>&1 || echo "[INFO] Role already associated."

# Wait for the instance profile to propagate before fetching its ARN
echo "[INFO] Waiting for instance profile propagation..."
for i in {1..10}; do
  aws iam get-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" > /dev/null 2>&1 && break
  echo "[INFO] Still waiting... ($i/10)"; sleep 5
done  

PROFILE_ARN=$(aws iam get-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" \
  --query "InstanceProfile.Arn" --output text)

# ---------- LAUNCH INSTANCE ----------
# ---------- LAUNCH OR REUSE INSTANCE ----------
echo "[INFO] Checking for existing ephemeral agent instance..."
EXISTING_AGENT=$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Name,Values=$AGENT_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null)

if [[ "$EXISTING_AGENT" != "None" && -n "$EXISTING_AGENT" ]]; then
  echo "[INFO] Reusing existing ephemeral agent instance: $EXISTING_AGENT"
  AGENT_INSTANCE_ID="$EXISTING_AGENT"
else
  echo "[INFO] Launching new ephemeral EC2 instance..."
  AGENT_INSTANCE_ID=$(aws ec2 run-instances --region "$REGION" \
    --image-id "$AMI_ID" --instance-type "t3.micro" \
    --iam-instance-profile Arn="$PROFILE_ARN" \
    --security-group-ids "$AGENT_SG_ID" --subnet-id "$SUBNET_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$AGENT_TAG}]" \
    --query 'Instances[0].InstanceId' --output text)

  echo "[INFO] Waiting for EC2 instance to reach 'running' state..."
  for i in {1..30}; do
    STATE=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$AGENT_INSTANCE_ID" \
      --query "Reservations[0].Instances[0].State.Name" --output text)
    [[ "$STATE" == "running" ]] && { echo "[INFO] Instance is running."; break; } || sleep 5
  done
fi

echo "[INFO] Waiting for instance to be managed by SSM..."
for i in {1..20}; do
  MANAGED=$(aws ssm describe-instance-information \
    --region "$REGION" \
    --query "InstanceInformationList[?InstanceId=='$AGENT_INSTANCE_ID'] | length(@)" \
    --output text)
  [[ "$MANAGED" -eq 1 ]] && { echo "[SUCCESS] Instance is now managed by SSM."; break; }
  echo "[INFO] Still not managed (attempt $i)..."; sleep 6
done

# ---------- INSTALL DOCKER AND START CONTAINER ----------
echo "[INFO] Installing Docker and launching Jenkins agent container..."
COMMAND_ID=$(aws ssm send-command --region "$REGION" --instance-ids "$AGENT_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" --comment "Start Jenkins agent container" \
  --parameters commands="[
    \"sudo apt update\",
    \"sudo apt install -y docker.io\",
    \"sudo systemctl enable docker\",
    \"sudo systemctl start docker\",
    \"docker --version\",
    \"docker rm -f jenkins-agent || true\",    
    \"sudo docker run -d --name jenkins-agent ${IMAGE_REF}\"
  ]" --query "Command.CommandId" --output text)

echo "[INFO] Waiting for container to launch..."
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations --region "$REGION" \
    --command-id "$COMMAND_ID" --details \
    --query "CommandInvocations[0].Status" --output text)

  [[ "$STATUS" == "Success" ]] && { echo "[SUCCESS] Container launched successfully."; break; } \
  || { echo "[INFO] Status: $STATUS (attempt $i)..."; sleep 5; }
done

echo "[INFO] Waiting for container to launch…"
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations …)
  [[ "$STATUS" == "Success" ]] && { echo "[SUCCESS] Container launched."; break; }
  echo "[INFO] Status: $STATUS (attempt $i)…"; sleep 5
done

# ---------- HEALTH-CHECK THE DOCKER CONTAINER ----------
echo "[INFO] Verifying container is running]"
HEALTH_ID=$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$AGENT_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters commands='["docker inspect -f {{.State.Running}} jenkins-agent"]' \
  --query "Command.CommandId" --output text)

# wait until docker inspect returns “true”
for i in {1..10}; do
  ALIVE=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$HEALTH_ID" \
    --details \
    --query "CommandInvocations[0].CommandPlugins[0].Output" --output text)
  [[ "$ALIVE" == "true" ]] && { echo "[SUCCESS] Container is healthy."; break; }
  echo "[WARN] Container not healthy yet ($i)…"; sleep 3
done

# ---------- TOOL VERSION CHECK ----------
echo "[INFO] Checking tool versions inside container..."
COMMAND_ID=$(aws ssm send-command --region "$REGION" --instance-ids "$AGENT_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" --comment "Tool version check" \
  --parameters commands="[
    \"echo Terraform version:\",
    \"docker exec jenkins-agent terraform version || echo 'Terraform not found'\",
    \"echo AWS CLI version:\",
    \"docker exec jenkins-agent aws --version || echo 'AWS CLI not found'\",
    \"echo GCloud SDK version:\",
    \"docker exec jenkins-agent gcloud version || echo 'GCloud not found'\"
  ]" --query "Command.CommandId" --output text)

echo "[INFO] Waiting for version check output..."
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations --region "$REGION" \
    --command-id "$COMMAND_ID" --details \
    --query "CommandInvocations[0].Status" --output text)

  if [[ "$STATUS" == "Success" ]]; then
    aws ssm list-command-invocations --region "$REGION" \
      --command-id "$COMMAND_ID" --details \
      --query "CommandInvocations[0].CommandPlugins[0].Output" --output text
    break
  else
    echo "[INFO] Status: $STATUS (attempt $i)..."
    sleep 5
  fi
done

# ---------- GET INSTANCE INFO ----------
echo "AGENT_ID=$AGENT_INSTANCE_ID" > ephem_env.txt

