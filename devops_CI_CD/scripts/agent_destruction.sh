#!/bin/bash
set -e

REGION="us-east-1"
AGENT_TAG="jenkins-agent-ephemeral"
AGENT_SG_NAME="jenkins-agent-sg"
AGENT_ROLE_NAME="jenkins-agent-role"
AGENT_PROFILE_NAME="jenkins-agent-profile"

echo "[INFO $(date +%T)] Looking for EC2 instance tagged '$AGENT_TAG'..."
INSTANCE_ID=$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Name,Values=$AGENT_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null)

if [[ "$INSTANCE_ID" != "None" && -n "$INSTANCE_ID" ]]; then
  echo "[INFO] Terminating EC2 instance: $INSTANCE_ID"
  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$REGION" > /dev/null
  echo "[INFO] Waiting for EC2 instance to terminate..."
  aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" --region "$REGION"
  echo "[INFO] Instance terminated."
else
  echo "[INFO] No running instance found with tag '$AGENT_TAG'."
fi

echo "[INFO $(date +%T)] Checking Instance Profile: $AGENT_PROFILE_NAME"
if aws iam get-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" > /dev/null 2>&1; then
  echo "[INFO] Detaching role from instance profile..."
  aws iam remove-role-from-instance-profile \
    --instance-profile-name "$AGENT_PROFILE_NAME" \
    --role-name "$AGENT_ROLE_NAME" > /dev/null 2>&1 || echo "[WARN] Role not attached or already removed."

  echo "[INFO] Deleting instance profile..."
  aws iam delete-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" > /dev/null 2>&1 || true

  for i in {1..10}; do
    aws iam get-instance-profile --instance-profile-name "$AGENT_PROFILE_NAME" > /dev/null 2>&1 \
      && { echo "[INFO] Still deleting instance profile ($i)..."; sleep 5; } \
      || { echo "[INFO] Instance profile deleted."; break; }
  done
else
  echo "[INFO] Instance profile not found."
fi

echo "[INFO $(date +%T)] Checking IAM Role: $AGENT_ROLE_NAME"
if aws iam get-role --role-name "$AGENT_ROLE_NAME" > /dev/null 2>&1; then
  echo "[INFO] Detaching policy..."
  aws iam detach-role-policy \
    --role-name "$AGENT_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore > /dev/null 2>&1 || echo "[WARN] Policy already detached or missing."

  echo "[INFO] Deleting IAM Role..."
  aws iam delete-role --role-name "$AGENT_ROLE_NAME" > /dev/null 2>&1 || true

  for i in {1..10}; do
    aws iam get-role --role-name "$AGENT_ROLE_NAME" > /dev/null 2>&1 \
      && { echo "[INFO] Still deleting role ($i)..."; sleep 5; } \
      || { echo "[INFO] IAM Role deleted."; break; }
  done
else
  echo "[INFO] IAM Role not found."
fi

echo "[INFO $(date +%T)] Checking Security Group '$AGENT_SG_NAME'..."
SG_ID=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=$AGENT_SG_NAME" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [[ "$SG_ID" != "None" && -n "$SG_ID" ]]; then
  echo "[INFO] Deleting Security Group: $SG_ID"
  aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" > /dev/null

  for i in {1..10}; do
    aws ec2 describe-security-groups --region "$REGION" --group-ids "$SG_ID" > /dev/null 2>&1 \
      && { echo "[INFO] Still deleting Security Group ($i)..."; sleep 5; } \
      || { echo "[INFO] Security Group deleted."; break; }
  done
else
  echo "[INFO] No matching Security Group found."
fi

echo "[INFO $(date +%T)] Cleanup complete. All ephemeral Jenkins agent resources have been destroyed."
