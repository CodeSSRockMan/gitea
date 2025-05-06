#!/bin/bash
set -e

# ---------- Configuration ----------
REGION="us-east-1"
DOCKER_HUB_USER="hescobarsanchez"       # <-- your Docker Hub user
IMAGE_NAME="jenkins-agent"              # <-- your image name
IMAGE_TAG="latest"                      # <-- your image tag
AGENT_INFO_SCRIPT="bash devops_CI_CD/scripts/check_status_agent.sh" # <--  path to the script that retrieves EC2 metadata

# ---------- Fetch EC2 metadata ----------
echo "[INFO] Executing ${AGENT_INFO_SCRIPT} to retrieve EC2 metadata..."
AGENT_INFO=$(${AGENT_INFO_SCRIPT})

INSTANCE_ID=$(echo "$AGENT_INFO" | awk -F: '/Instance ID/ {gsub(/ /,"",$2); print $2}')
SUBNET_ID=$(echo "$AGENT_INFO" | awk -F: '/Subnet ID/    {gsub(/ /,"",$2); print $2}')
VPC_ID=$(echo "$AGENT_INFO" | awk -F: '/VPC ID/       {gsub(/ /,"",$2); print $2}')
SG_ID=$(echo "$AGENT_INFO" | awk -F: '/Security Groups/ {gsub(/ /,"",$2); print $2}')

if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
  echo "[ERROR] Could not extract Instance ID. Aborting."
  exit 1
fi

echo "[INFO] Instance ID: $INSTANCE_ID"
echo "[INFO] Subnet ID:   $SUBNET_ID"
echo "[INFO] VPC ID:      $VPC_ID"
echo "[INFO] SG ID:       $SG_ID"

# Full Docker image reference
IMAGE_REF="${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

# ---------- Install & run Docker container on agent via SSM ----------
echo "[INFO] Sending SSM command to install Docker & run ${IMAGE_REF}..."

COMMAND_ID=$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Install Docker & launch Jenkins agent container" \
  --parameters commands="[\
    \"sudo apt update\",\
    \"sudo apt install -y docker.io\",\
    \"sudo systemctl enable docker\",\
    \"sudo systemctl start docker\",\
    \"docker --version\",\
    \"sudo docker run -d --name jenkins-agent ${IMAGE_REF}\"\
  ]" \
  --query "Command.CommandId" --output text)

echo "[INFO] Waiting for Docker & container to complete..."
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --details \
    --query "CommandInvocations[0].Status" --output text)

  if [[ "$STATUS" == "Success" ]]; then
    echo "[SUCCESS] Docker installed and container launched: ${IMAGE_REF}"
    break
  elif [[ "$STATUS" =~ ^(Failed|Cancelled)$ ]]; then
    echo "[ERROR] SSM install/run command failed: $STATUS"
    exit 1
  else
    echo "[INFO] Status: $STATUS (attempt $i)..."
    sleep 5
  fi
done

# ---------- Version checks ----------
echo "[INFO] Sending SSM command to print versions..."

COMMAND_ID=$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Print versions of installed tools" \
  --parameters commands="[
  \"echo Starting agent...\",
  \
  \"echo Terraform version:\",
  \"docker exec jenkins-agent terraform version || echo 'Terraform not installed in container'\",
  \"echo AWS CLI version:\",
  \"docker exec jenkins-agent aws --version || echo 'AWS CLI not installed in container'\",
  \"echo GCloud SDK version:\",
  \"docker exec jenkins-agent gcloud version || echo 'GCloud not installed in container'\"
]" \
  --query "Command.CommandId" --output text)

echo "[INFO] Waiting for version check to complete..."
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --details \
    --query "CommandInvocations[0].Status" --output text)

  if [[ "$STATUS" == "Success" ]]; then
    echo "[INFO] Versions detected on agent:"
    aws ssm list-command-invocations \
      --region "$REGION" \
      --command-id "$COMMAND_ID" \
      --details \
      --query "CommandInvocations[0].CommandPlugins[0].Output" --output text
    break
  elif [[ "$STATUS" =~ ^(Failed|Cancelled)$ ]]; then
    echo "[ERROR] Version check failed: $STATUS"
    exit 1
  else
    echo "[INFO] Status: $STATUS (attempt $i)..."
    sleep 5
  fi
done
