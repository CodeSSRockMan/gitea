#!/bin/bash
set -e

REGION="us-east-1"
AGENT_TAG="jenkins-agent-ephemeral"

echo "[INFO] Looking for EC2 instances with tag Name=$AGENT_TAG in region $REGION..."

# List all instances with the given tag, regardless of state
ALL_INSTANCES=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$AGENT_TAG" \
  --query "Reservations[].Instances[].[InstanceId,State.Name]" \
  --output text)

if [[ -z "$ALL_INSTANCES" ]]; then
  echo "[INFO] No EC2 instances found with tag Name=$AGENT_TAG."
  exit 0
fi

echo "[INFO] Instances with tag Name=$AGENT_TAG:"
echo "$ALL_INSTANCES"
echo ""

# Try to find one that's running
INSTANCE_ID=$(echo "$ALL_INSTANCES" | awk '$2 == "running" {print $1; exit}')

if [[ -z "$INSTANCE_ID" ]]; then
  echo "[WARN] No running instance found. Here is the status of other instances:"
  echo "$ALL_INSTANCES"
  exit 0
fi

# Proceed with normal inspection if a running instance was found
echo "[INFO] Found running instance: $INSTANCE_ID"
PUBLIC_IP=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
PRIVATE_IP=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
AMI_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].ImageId" --output text)
SUBNET_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].SubnetId" --output text)
VPC_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].VpcId" --output text)
SG_IDS=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].SecurityGroups[*].GroupId" --output text)
IAM_ROLE=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" --output text | awk -F'/' '{print $NF}')

echo ""
echo "[INFO] Jenkins Agent details:"
echo "Instance ID     : $INSTANCE_ID"
echo "Public IP       : $PUBLIC_IP"
echo "Private IP      : $PRIVATE_IP"
echo "AMI ID          : $AMI_ID"
echo "Subnet ID       : $SUBNET_ID"
echo "VPC ID          : $VPC_ID"
echo "Security Groups : $SG_IDS"
echo "IAM Role        : $IAM_ROLE"
echo ""

for SG_ID in $SG_IDS; do
  echo "[INFO] Rules for Security Group $SG_ID:"
  aws ec2 describe-security-groups --region "$REGION" --group-ids "$SG_ID" \
    --query "SecurityGroups[0].IpPermissions" --output table
done
