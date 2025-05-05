#!/bin/bash
set -e

# Configure region
REGION="us-east-1"
MASTER_TAG="jenkins-master"

echo "[INFO] Fetching Jenkins Master instance information..."

# Get Instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$MASTER_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

if [ "$INSTANCE_ID" == "None" ]; then
  echo "[ERROR] No running instance found with tag Name=$MASTER_TAG"
  exit 1
fi

# Get additional details
PUBLIC_IP=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
PRIVATE_IP=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
AMI_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].ImageId" --output text)
SUBNET_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].SubnetId" --output text)
VPC_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].VpcId" --output text)
SG_IDS=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].SecurityGroups[*].GroupId" --output text)
IAM_ROLE=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" --output text | awk -F'/' '{print $NF}')

# Print summary
echo ""
echo "[INFO] Jenkins Master found:"
echo "Instance ID     : $INSTANCE_ID"
echo "Public IP       : $PUBLIC_IP"
echo "Private IP      : $PRIVATE_IP"
echo "AMI ID          : $AMI_ID"
echo "Subnet ID       : $SUBNET_ID"
echo "VPC ID          : $VPC_ID"
echo "Security Groups : $SG_IDS"
echo "IAM Role        : $IAM_ROLE"
echo ""

# Show security group rules
for SG_ID in $SG_IDS; do
  echo "[INFO] Rules for Security Group $SG_ID:"
  aws ec2 describe-security-groups --region "$REGION" --group-ids "$SG_ID" \
    --query "SecurityGroups[0].IpPermissions" --output table
done
