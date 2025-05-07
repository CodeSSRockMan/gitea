source env.sh
# … ahora REGION y MASTER_TAG ya vienen preexportados …
echo "[DEBUG] AWS identity:"
aws sts get-caller-identity --region "$REGION" || { echo "[ERROR] AWS credentials not set"; exit 1; }

echo "[INFO] Fetching Jenkins Master info..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$MASTER_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

AMI_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].ImageId" --output text)
SUBNET_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].SubnetId" --output text)
VPC_ID=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].VpcId" --output text)

cat >> "$STATE_FILE" <<EOF
INSTANCE_ID=$INSTANCE_ID
AMI_ID=$AMI_ID
SUBNET_ID=$SUBNET_ID
VPC_ID=$VPC_ID
EOF
