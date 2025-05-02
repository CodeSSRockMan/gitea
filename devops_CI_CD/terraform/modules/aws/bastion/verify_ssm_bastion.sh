#!/bin/bash
check_console_logs_for_ssm() {
  echo -e "\n📜 Fetching EC2 console output to analyze SSM agent logs..."

  CONSOLE_LOG=$(aws ec2 get-console-output \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --output text)

  echo "$CONSOLE_LOG" | grep -qi "ssm-agent" \
    && echo "✅ Found references to ssm-agent in console output." \
    || echo "❌ No mention of ssm-agent found. It may not have installed."

  echo "$CONSOLE_LOG" | grep -qi "snap install amazon-ssm-agent" \
    && echo "✅ snap installation command found." \
    || echo "⚠️ No 'snap install amazon-ssm-agent' command found."

  echo "$CONSOLE_LOG" | grep -q "Failed" && {
    echo "⚠️ Console output shows some failed units:"
    echo "$CONSOLE_LOG" | grep "Failed"
  }

  echo -e "\n💡 Tip: ensure your User Data includes:"
  echo "apt update -y && apt install -y snapd && snap install amazon-ssm-agent --classic"
}

# CONFIGURATION
INSTANCE_ID="$1"
REGION="${2:-us-east-1}"
RDS_SG_PORT=3306

if [[ -z "$INSTANCE_ID" ]]; then
  echo "❌ Usage: $0 <ec2-instance-id> [region]"
  exit 1
fi

echo "🔍 Verifying EC2 Instance ID: $INSTANCE_ID in region: $REGION"

# 1. Check EC2 exists
EC2_INFO=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query "Reservations[0].Instances[0]" \
  --output json 2>/dev/null)

[[ -z "$EC2_INFO" ]] && { echo "❌ Instance not found."; exit 1; }

# 2. IAM Role attached?
INSTANCE_PROFILE_NAME=$(echo "$EC2_INFO" | jq -r '.IamInstanceProfile.Arn' | cut -d '/' -f2)
[[ "$INSTANCE_PROFILE_NAME" == "null" ]] && { echo "❌ No IAM instance profile attached."; exit 1; }

echo "✅ IAM Instance Profile: $INSTANCE_PROFILE_NAME"

# Get the actual role name from the instance profile
ROLE_NAME=$(aws iam get-instance-profile \
  --instance-profile-name "$INSTANCE_PROFILE_NAME" \
  --query "InstanceProfile.Roles[0].RoleName" \
  --output text 2>/dev/null)

[[ "$ROLE_NAME" == "None" || -z "$ROLE_NAME" ]] && {
  echo "❌ Could not resolve the IAM role from instance profile."
  exit 1
}

echo "✅ IAM Role resolved: $ROLE_NAME"

# 3. Check IAM Policy
POLICIES=$(aws iam list-attached-role-policies \
  --role-name "$ROLE_NAME" \
  --query "AttachedPolicies[*].PolicyName" --output text)

echo "$POLICIES" | grep -q "AmazonSSMManagedInstanceCore" \
  && echo "✅ Policy AmazonSSMManagedInstanceCore is attached." \
  || echo "⚠️  Policy AmazonSSMManagedInstanceCore is missing."

# 4. Network Details
PRIVATE_IP=$(echo "$EC2_INFO" | jq -r '.PrivateIpAddress')
SG_IDS=$(echo "$EC2_INFO" | jq -r '.SecurityGroups[].GroupId')
SUBNET_ID=$(echo "$EC2_INFO" | jq -r '.SubnetId')

echo "🔐 Security Groups: $SG_IDS"
echo "🌐 Subnet ID: $SUBNET_ID"
echo "📍 Private IP: $PRIVATE_IP"

# 5. Internet connectivity (from YOUR machine)
echo -n "🌐 Checking outbound internet (ping google.com)... "
ping -c 1 -W 2 google.com >/dev/null 2>&1 \
  && echo "✅ Available" \
  || echo "❌ Unreachable (may affect tunnel to SSM)"

# 6. SSM registration
SSM_STATUS=$(aws ssm describe-instance-information \
  --region "$REGION" \
  --query "InstanceInformationList[?InstanceId=='$INSTANCE_ID'].PingStatus" \
  --output text)

if [[ "$SSM_STATUS" == "Online" ]]; then
  echo "✅ SSM PingStatus: $SSM_STATUS"
else
  echo "❌ SSM PingStatus: $SSM_STATUS — agent may be missing, off, or no outbound internet."
  check_console_logs_for_ssm
  exit 1
fi


# 7. SG Rules for MySQL (3306)
echo -e "\n🔍 Checking outbound SG rules for MySQL (port 3306)..."
for sg in $SG_IDS; do
  RULE_FOUND=$(aws ec2 describe-security-groups \
    --group-ids "$sg" --region "$REGION" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`$RDS_SG_PORT\`].IpRanges[*].CidrIp" \
    --output text)

  [[ -n "$RULE_FOUND" ]] \
    && echo "✅ SG $sg allows outbound on port 3306 to: $RULE_FOUND" \
    || echo "⚠️  SG $sg has no outbound rule for port 3306 (check RDS SG too)"
done

# 8. Attempt SSM session
echo -e "\n🧪 Attempting to open a test SSM session..."
read -rp "❓ Do you want to try starting a live SSM session now? (y/n): " confirm_ssm

[[ "$confirm_ssm" == "y" ]] \
  && aws ssm start-session --target "$INSTANCE_ID" --region "$REGION" \
  || echo "ℹ️  Skipping SSM session test."

check_console_logs_for_ssm() {
  echo -e "\n📜 Fetching EC2 console output to analyze SSM agent logs..."

  CONSOLE_LOG=$(aws ec2 get-console-output \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --output text)

  echo "$CONSOLE_LOG" | grep -qi "ssm-agent" \
    && echo "✅ Found references to ssm-agent in console output." \
    || echo "❌ No mention of ssm-agent found. It may not have installed."

  echo "$CONSOLE_LOG" | grep -qi "snap install amazon-ssm-agent" \
    && echo "✅ snap installation command found." \
    || echo "⚠️ No 'snap install amazon-ssm-agent' command found."

  echo "$CONSOLE_LOG" | grep -q "Failed" && {
    echo "⚠️ Console output shows some failed units:"
    echo "$CONSOLE_LOG" | grep "Failed"
  }

  echo -e "\n💡 Tip: ensure your User Data includes:"
  echo "apt update -y && apt install -y snapd && snap install amazon-ssm-agent --classic"
}
