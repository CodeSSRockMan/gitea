#!/bin/bash
set -e

# Load environment and previous state
source env.sh

[[ -f "$STATE_FILE" ]] || { echo "[ERROR] STATE_FILE not found: $STATE_FILE"; exit 1; }

source "$STATE_FILE"

echo "[INFO] Loaded state:"
grep -v 'PASSWORD' "$STATE_FILE" | while read -r line; do
  echo "  $line"
done

# ---------- SECURITY GROUP ----------
echo "[INFO] Checking agent Security Group..."
AGENT_SG_ID=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=$AGENT_SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

if [[ -z "$AGENT_SG_ID" || "$AGENT_SG_ID" == "None" ]]; then
  echo "[INFO] Creating new Security Group..."
  AGENT_SG_ID=$(aws ec2 create-security-group --region "$REGION" \
    --group-name "$AGENT_SG_NAME" \
    --description "Jenkins Agent SG" \
    --vpc-id "$VPC_ID" \
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
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
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

aws iam add-role-to-instance-profile \
  --instance-profile-name "$AGENT_PROFILE_NAME" \
  --role-name "$AGENT_ROLE_NAME" > /dev/null 2>&1 || echo "[INFO] Role already associated."

PROFILE_ARN=$(aws iam get-instance-profile \
  --instance-profile-name "$AGENT_PROFILE_NAME" \
  --query "InstanceProfile.Arn" --output text)

# ---------- Save output variables ----------
cat >> "$STATE_FILE" <<EOF
AGENT_SG_ID=$AGENT_SG_ID
PROFILE_ARN=$PROFILE_ARN
EOF

echo "[INFO] Security Group and IAM configuration completed."
echo "[INFO] Saved: AGENT_SG_ID=$AGENT_SG_ID, PROFILE_ARN=$PROFILE_ARN"
