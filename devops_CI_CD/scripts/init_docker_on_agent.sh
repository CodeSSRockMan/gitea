#!/bin/bash
set -e

REGION="us-east-1"

echo "[INFO] Executing check_status_agent.sh to retrieve EC2 metadata..."
AGENT_INFO=$(./check_status_agent.sh)

# Extrae datos
INSTANCE_ID=$(echo "$AGENT_INFO" | grep "Instance ID" | awk -F: '{print $2}' | xargs)
SUBNET_ID=$(echo "$AGENT_INFO" | grep "Subnet ID" | awk -F: '{print $2}' | xargs)
VPC_ID=$(echo "$AGENT_INFO" | grep "VPC ID" | awk -F: '{print $2}' | xargs)
SECURITY_GROUP=$(echo "$AGENT_INFO" | grep "Security Groups" | awk -F: '{print $2}' | xargs)

if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
  echo "[ERROR] Could not extract Instance ID. Aborting."
  exit 1
fi

echo "[INFO] Instance ID: $INSTANCE_ID"
echo "[INFO] Subnet ID: $SUBNET_ID"
echo "[INFO] VPC ID: $VPC_ID"
echo "[INFO] Security Group ID: $SECURITY_GROUP"

echo "[INFO] Sending SSM command to install Docker..."

COMMAND_ID=$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Install Docker" \
  --parameters 'commands=[
    "sudo apt update",
    "sudo apt install -y docker.io",
    "sudo systemctl enable docker",
    "sudo systemctl start docker",
    "sudo docker --version",
    "sudo docker run hescobarsanchez/jenkins-agent:latest"

  ]' \
  --query "Command.CommandId" \
  --output text)

# Esperar a que el comando de instalación termine
echo "[INFO] Waiting for Docker installation to complete..."
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --details \
    --query "CommandInvocations[0].Status" \
    --output text)

  if [[ "$STATUS" == "Success" ]]; then
    echo "[SUCCESS] Docker installed successfully."
    break
  elif [[ "$STATUS" == "Failed" || "$STATUS" == "Cancelled" ]]; then
    echo "[ERROR] Command failed with status: $STATUS"
    exit 1
  else
    echo "[INFO] Status: $STATUS (attempt $i)..."
    sleep 5
  fi
done

# Verificar versiones instaladas
echo "[INFO] Sending SSM command to print versions of Terraform, AWS CLI and GCloud..."

COMMAND_ID=$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Print versions of installed tools" \
  --parameters 'commands=[
    "echo Terraform version:",
    "terraform version",
    "echo AWS CLI version:",
    "aws --version",
    "echo GCloud SDK version:",
    "gcloud version"
  ]' \
  --query "Command.CommandId" \
  --output text)

echo "[INFO] Waiting for version check to complete..."
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --details \
    --query "CommandInvocations[0].Status" \
    --output text)

  if [[ "$STATUS" == "Success" ]]; then
    echo "[INFO] Versions detected on agent:"
    aws ssm list-command-invocations \
      --region "$REGION" \
      --command-id "$COMMAND_ID" \
      --details \
      --query "CommandInvocations[0].CommandPlugins[0].Output" \
      --output text
    break
  elif [[ "$STATUS" == "Failed" || "$STATUS" == "Cancelled" ]]; then
    echo "[ERROR] Version check failed with status: $STATUS"
    exit 1
  else
    echo "[INFO] Status: $STATUS (attempt $i)..."
    sleep 5
  fi
done
