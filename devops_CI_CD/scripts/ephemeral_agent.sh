#!/bin/bash
set -e

REGION="us-east-1"
MASTER_TAG="jenkins-master"
AGENT_TAG="jenkins-agent-ephemeral"
AGENT_ROLE_NAME="jenkins-agent-role"
AGENT_PROFILE_NAME="jenkins-agent-profile"
AGENT_SG_NAME="jenkins-agent-sg"

echo "[INFO] Fetching Jenkins Master info..."
INSTANCE_ID=$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Name,Values=$MASTER_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

if [[ "$INSTANCE_ID" == "None" || -z "$INSTANCE_ID" ]]; then
  echo "[ERROR] Jenkins Master not found."
  exit 1
fi

AMI_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].ImageId" --output text)
SUBNET_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].SubnetId" --output text)
VPC_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].VpcId" --output text)

echo "[INFO] Checking if Security Group '$AGENT_SG_NAME' already exists..."
EXISTING_SG_ID=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=$AGENT_SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [[ "$EXISTING_SG_ID" != "None" && -n "$EXISTING_SG_ID" ]]; then
  AGENT_SG_ID="$EXISTING_SG_ID"
  echo "[INFO] Security Group already exists. Using: $AGENT_SG_ID"
else
  echo "[INFO] Creating Security Group for agent..."
  AGENT_SG_ID=$(aws ec2 create-security-group --region "$REGION" \
    --group-name "$AGENT_SG_NAME" \
    --description "Security group for Jenkins agent" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)

  echo "[INFO] Allowing outbound access..."
  aws ec2 authorize-security-group-egress \
    --region "$REGION" \
    --group-id "$AGENT_SG_ID" \
    --protocol -1 --cidr 0.0.0.0/0 \
    2>/dev/null || echo "[WARN] Outbound rule already exists."
  
  echo "[INFO] Security Group created: $AGENT_SG_ID"
fi

echo "[INFO] Ensuring IAM Role and Instance Profile exist..."
if ! aws iam get-role --role-name "$AGENT_ROLE_NAME" > /dev/null 2>&1; then
  aws iam create-role --role-name "$AGENT_ROLE_NAME" \
    --assume-role-policy-document file://<(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF
  ) > /dev/null
fi

aws iam attach-role-policy --role-name "$AGENT_ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore > /dev/null || true

if ! aws iam get-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" > /dev/null 2>&1; then
  aws iam create-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" > /dev/null
fi

if ! aws iam get-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" \
  --query "InstanceProfile.Roles[?RoleName=='$AGENT_ROLE_NAME'] | [0]" --output text | grep -q "$AGENT_ROLE_NAME"; then
  aws iam add-role-to-instance-profile \
    --instance-profile-name "$AGENT_PROFILE_NAME" \
    --role-name "$AGENT_ROLE_NAME" > /dev/null
fi

echo "[INFO] Waiting for Instance Profile to be ready..."
for i in {1..30}; do
  PROFILE_ARN=$(aws iam get-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" \
    --query 'InstanceProfile.Arn' --output text 2>/dev/null)
  [[ "$PROFILE_ARN" != "None" && -n "$PROFILE_ARN" ]] \
    && { echo "[INFO] Instance Profile ready: $PROFILE_ARN"; break; } \
    || { echo "[INFO] Waiting for propagation ($i)..."; sleep 5; }
done

# Generate user-data for EC2 to install Docker only
cat > init_agent.sh <<EOF
#!/bin/bash
apt update
apt install -y docker.io
systemctl enable docker
systemctl start docker
EOF

chmod +x init_agent.sh

echo "[INFO] Launching EC2 instance with Docker only..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type "t3.micro" \
  --iam-instance-profile Arn="$PROFILE_ARN" \
  --security-group-ids "$AGENT_SG_ID" \
  --subnet-id "$SUBNET_ID" \
  --user-data file://init_agent.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$AGENT_TAG}]" \
  --query 'Instances[0].InstanceId' --output text)

echo "[INFO] Instance launched: $INSTANCE_ID"
