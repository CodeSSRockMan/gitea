#!/bin/bash
set -e

# 04-docker-run.sh — Install Docker & launch Jenkins agent container

# Load configuration and previous state
source env.sh
source "$STATE_FILE"

echo "[INFO] Installing Docker and launching Jenkins agent container..."

# Send SSM command to install Docker and run the container (idempotent)
COMMAND_ID=$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$AGENT_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Start Jenkins agent container" \
  --parameters commands="[
    \"sudo apt update\",
    \"sudo apt install -y docker.io\",
    \"sudo systemctl enable docker\",
    \"sudo systemctl start docker\",
    \"docker --version\",
    \"docker rm -f jenkins-agent || true\",
    \"sudo docker run -d --name jenkins-agent ${IMAGE_REF}\"
  ]" \
  --query "Command.CommandId" --output text)

# Save the SSM command ID for possible later inspection
cat >> "$STATE_FILE" <<EOF
DOCKER_COMMAND_ID=$COMMAND_ID
EOF

echo "[INFO] Waiting for SSM command to succeed (install & run)…"
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --details \
    --query "CommandInvocations[0].Status" --output text)

  if [[ "$STATUS" == "Success" ]]; then
    echo "[SUCCESS] Docker installed and container launched."
    break
  fi

  echo "[INFO] Current status: $STATUS (attempt $i/20)…"
  sleep 5
done
