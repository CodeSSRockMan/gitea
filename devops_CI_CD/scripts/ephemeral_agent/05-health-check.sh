#!/bin/bash
set -e

# 05-health-check.sh — Verify Jenkins agent container is running

source env.sh
source "$STATE_FILE"

echo "[INFO] Performing health check on Jenkins agent container..."

# Send SSM command to inspect container state
HEALTH_ID=$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$AGENT_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Health check: docker inspect" \
  --parameters commands='["docker inspect -f {{.State.Running}} jenkins-agent"]' \
  --query "Command.CommandId" --output text)

# Persist HEALTH_ID for later debugging
cat >> "$STATE_FILE" <<EOF
HEALTH_ID=$HEALTH_ID
EOF

# Poll until the container reports "true" or timeout
for i in {1..10}; do
  ALIVE=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$HEALTH_ID" \
    --details \
    --query "CommandInvocations[0].CommandPlugins[0].Output" --output text)

  [[ "$ALIVE" == "true" ]] \
    && { echo "[SUCCESS] Container is healthy."; CONTAINER_HEALTH=true; break; } \
    || { echo "[WARN] Container not healthy yet (attempt $i/10)…"; sleep 3; }
done

# Save final health status as well
cat >> "$STATE_FILE" <<EOF
CONTAINER_HEALTH=$CONTAINER_HEALTH
EOF
