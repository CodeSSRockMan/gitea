#!/bin/bash
set -e

# Load config and previously saved state
source env.sh
source "$STATE_FILE"

echo "[INFO] Checking for an existing ephemeral agent instance..."
EXISTING_AGENT=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$AGENT_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null)

if [[ -n "$EXISTING_AGENT" && "$EXISTING_AGENT" != "None" ]]; then
  echo "[INFO] Reusing existing agent instance: $EXISTING_AGENT"
  AGENT_INSTANCE_ID="$EXISTING_AGENT"
else
  echo "[INFO] Launching new ephemeral EC2 instance..."
  AGENT_INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type "t3.micro" \
    --iam-instance-profile Arn="$PROFILE_ARN" \
    --security-group-ids "$AGENT_SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$AGENT_TAG}]" \
    --query "Instances[0].InstanceId" --output text)

  echo "[INFO] Waiting for EC2 instance to enter 'running' state..."
  for i in {1..30}; do
    STATE=$(aws ec2 describe-instances \
      --region "$REGION" \
      --instance-ids "$AGENT_INSTANCE_ID" \
      --query "Reservations[0].Instances[0].State.Name" --output text)
    if [[ "$STATE" == "running" ]]; then
      echo "[INFO] Instance is now running."
      break
    fi
    echo "[INFO] Current state: $STATE (attempt $i/30)"
    sleep 10
  done
fi

# Save ID and private IP for downstream steps
AGENT_IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$AGENT_INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

cat >> "$STATE_FILE" <<EOF
AGENT_INSTANCE_ID=$AGENT_INSTANCE_ID
AGENT_IP=$AGENT_IP
EOF

echo "[INFO] Agent instance ready: ID=$AGENT_INSTANCE_ID, IP=$AGENT_IP"
