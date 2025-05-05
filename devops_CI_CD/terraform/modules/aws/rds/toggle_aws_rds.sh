#!/bin/bash

# CONFIGURATION
DB_INSTANCE_ID="gitea-db-instance"
REGION="us-east-1"
REQUIRED_PERMISSIONS=(
  "rds:DescribeDBInstances"
  "rds:StartDBInstance"
  "rds:StopDBInstance"
)
RDS_FULL_ACCESS_POLICY="arn:aws:iam::aws:policy/AmazonRDSFullAccess"


wait_for_status() {
  local desired_status=$1
  local max_wait=${2:-300}  # default 5 minutes
  local interval=5
  local elapsed=0

  echo "⏳ Waiting for status: $desired_status..."
  while true; do
    current_status=$(aws rds describe-db-instances \
      --region "$REGION" \
      --db-instance-identifier "$DB_INSTANCE_ID" \
      --query "DBInstances[0].DBInstanceStatus" \
      --output text 2>/dev/null)

    if [[ "$current_status" == "$desired_status" ]]; then
      echo "✅ Instance is now: $current_status (after ${elapsed}s)"
      break
    fi

    ((elapsed+=interval))
    echo "🔁 Still $current_status... (${elapsed}s)"
    sleep $interval

    [[ $elapsed -ge $max_wait ]] && {
      echo "⛔ Timeout: status did not reach '$desired_status' after ${elapsed}s"
      break
    }
  done
}



echo "🔍 Checking current AWS identity..."

CURRENT_IDENTITY=$(aws sts get-caller-identity --query "Arn" --output text 2>/dev/null)
if [[ $? -ne 0 ]]; then
  echo "❌ Unable to detect AWS credentials. Run 'aws configure' first."
  exit 1
fi

echo "✅ Current identity: $CURRENT_IDENTITY"
read -rp "❓ Is this the correct identity to manage the RDS instance? (y/n): " confirm_user
if [[ "$confirm_user" != "y" ]]; then
  echo -e "\n⚠️ Switch user with:\n   aws configure --profile YOUR_PROFILE_NAME\n   export AWS_PROFILE=YOUR_PROFILE_NAME"
  exit 1
fi

#CHECK IAM PERMISSIONS
echo -e "\n🔐 Verifying required permissions..."

MISSING_PERMS=()
for perm in "${REQUIRED_PERMISSIONS[@]}"; do
  result=$(aws iam simulate-principal-policy \
    --policy-source-arn "$CURRENT_IDENTITY" \
    --action-names "$perm" \
    --query 'EvaluationResults[0].EvalDecision' \
    --output text 2>/dev/null)

  [[ "$result" == "allowed" ]] \
    && echo "✅ $perm → allowed" \
    || {
      echo "❌ $perm → denied"
      MISSING_PERMS+=("$perm")
    }
done

[[ ${#MISSING_PERMS[@]} -eq 0 ]] || {
  echo -e "\n🚫 You are missing ${#MISSING_PERMS[@]} permission(s):"
  for mp in "${MISSING_PERMS[@]}"; do echo "   - $mp"; done

  read -rp "❓ Would you like to attach AmazonRDSFullAccess to this user? (y/n): " grant
  [[ "$grant" == "y" ]] && {
    USERNAME=$(basename "$CURRENT_IDENTITY" | cut -d '/' -f2)
    echo "🔧 Attaching policy to '$USERNAME'..."
    aws iam attach-user-policy --user-name "$USERNAME" --policy-arn "$RDS_FULL_ACCESS_POLICY"
    echo "✅ Policy attached. Please re-run the script."
    exit 0
  } || {
    echo -e "\n📌 To add it manually:"
    echo "aws iam attach-user-policy --user-name YOUR_USER --policy-arn $RDS_FULL_ACCESS_POLICY"
    exit 1
  }
}


# GET RDS STATUS
echo -e "\n📡 Retrieving RDS instance info..."
RDS_JSON=$(aws rds describe-db-instances --region "$REGION" --db-instance-identifier "$DB_INSTANCE_ID" --output json)
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to retrieve RDS info. Verify instance ID and region."
  exit 1
fi

DB_STATUS=$(echo "$RDS_JSON" | jq -r '.DBInstances[0].DBInstanceStatus')
PUBLICLY_ACCESSIBLE=$(echo "$RDS_JSON" | jq -r '.DBInstances[0].PubliclyAccessible')
ENCRYPTED=$(echo "$RDS_JSON" | jq -r '.DBInstances[0].StorageEncrypted')
ENDPOINT=$(echo "$RDS_JSON" | jq -r '.DBInstances[0].Endpoint.Address')
ENGINE=$(echo "$RDS_JSON" | jq -r '.DBInstances[0].Engine')
VERSION=$(echo "$RDS_JSON" | jq -r '.DBInstances[0].EngineVersion')
CLASS=$(echo "$RDS_JSON" | jq -r '.DBInstances[0].DBInstanceClass')

echo -e "\n📊 RDS INSTANCE STATUS:"
echo "🆔 Instance ID      : $DB_INSTANCE_ID"
echo "🌐 Endpoint         : $ENDPOINT"
echo "🔒 Encrypted        : $ENCRYPTED"
echo "🌍 Public Access    : $PUBLICLY_ACCESSIBLE"
echo "🧠 Engine           : $ENGINE $VERSION"
echo "📦 Instance Class   : $CLASS"
echo "📡 Current Status   : $DB_STATUS"

[[ "$PUBLICLY_ACCESSIBLE" == "true" ]] && echo "⚠️ WARNING: RDS is publicly accessible!"

# PROMPT TO ACT
echo ""
case "$DB_STATUS" in
  available)
    read -rp "🛑 The RDS instance is RUNNING. Do you want to STOP it? (y/n): " confirm_stop
    [[ "$confirm_stop" == "y" ]] && {
    echo "🛑 Stopping instance..."
    aws rds stop-db-instance --region "$REGION" --db-instance-identifier "$DB_INSTANCE_ID" >/dev/null
    wait_for_status "stopped"
    } || echo "⏹️  No action taken."

    ;;
  stopped)
    read -rp "🚀 The RDS instance is STOPPED. Do you want to START it? (y/n): " confirm_start
    [[ "$confirm_start" == "y" ]] && {
    echo "🚀 Starting instance..."
    aws rds start-db-instance --region "$REGION" --db-instance-identifier "$DB_INSTANCE_ID" >/dev/null
    wait_for_status "available"
    } || echo "⏹️  No action taken."

    ;;
  *)
    echo "⚠️ Instance is in state: $DB_STATUS. No toggle action available."
    ;;
esac

