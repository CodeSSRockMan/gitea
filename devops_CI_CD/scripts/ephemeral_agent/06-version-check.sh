#!/bin/bash
set -e

# 06-version-check.sh — Verify tool versions inside the Jenkins agent container

# 1) Load configuration and previous state
source env.sh
source "$STATE_FILE"

echo "[INFO] Checking tool versions inside the container..."

# 2) Send SSM command that runs multiple docker exec calls
VERSION_CMD_ID=$(aws ssm send-command \
  --region "$REGION" \
  --instance-ids "$AGENT_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Tool version check" \
  --parameters commands="[
    \"echo Terraform version:\",
    \"docker exec jenkins-agent terraform version || echo 'Terraform not found'\",
    \"echo AWS CLI version:\",
    \"docker exec jenkins-agent aws --version || echo 'AWS CLI not found'\",
    \"echo GCloud SDK version:\",
    \"docker exec jenkins-agent gcloud version || echo 'GCloud not found'\"
  ]" \
  --query "Command.CommandId" --output text)

# 3) Persist the command ID for later debugging
cat >> "$STATE_FILE" <<EOF
VERSION_CMD_ID=$VERSION_CMD_ID
EOF

# 4) Wait for the SSM command to succeed
for i in {1..20}; do
  STATUS=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$VERSION_CMD_ID" \
    --details \
    --query "CommandInvocations[0].Status" --output text)

  [[ "$STATUS" == "Success" ]] \
    && { echo "[SUCCESS] Version check completed."; break; } \
    || { echo "[INFO] Current status: $STATUS (attempt $i/20)…"; sleep 5; }
done

# 5) Retrieve and print the output
OUTPUT=$(aws ssm list-command-invocations \
  --region "$REGION" \
  --command-id "$VERSION_CMD_ID" \
  --details \
  --query "CommandInvocations[0].CommandPlugins[0].Output" --output text)

echo "$OUTPUT"

# 6) Optionally persist a single-line summary for downstream use
TOOL_VERSIONS=$(echo "$OUTPUT" | tr '\n' ' | ')
cat >> "$STATE_FILE" <<EOF
TOOL_VERSIONS="$TOOL_VERSIONS"
EOF
