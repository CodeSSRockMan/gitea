#!/bin/bash

INSTANCE_ID="$1"

if [ -z "$INSTANCE_ID" ]; then
  echo "❌ Debes proporcionar el ID de la instancia EC2."
  echo "Uso: $0 i-01d6d8496ec5d4a8a"
  exit 1
fi

echo "🔍 Diagnóstico completo de la infraestructura para despliegue de app en AWS"
echo "=============================================================================="

# Detalles de EC2
echo -e "\n📦 Información de la instancia EC2:"
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[].Instances[].{
    Estado: State.Name,
    Tipo: InstanceType,
    IP_Publica: PublicIpAddress,
    Subnet: SubnetId,
    VPC: VpcId,
    SGs: SecurityGroups[*].GroupId,
    Role: IamInstanceProfile.Arn
  }' --output table

# Route Table
SUBNET_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].SubnetId" --output text)
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
  --query "RouteTables[0].RouteTableId" --output text)

echo -e "\n🛣️  Tabla de ruteo asociada ($ROUTE_TABLE_ID):"
aws ec2 describe-route-tables --route-table-ids "$ROUTE_TABLE_ID" \
  --query "RouteTables[0].Routes[*].{Destino:DestinationCidrBlock, Target:GatewayId}" --output table

# Security Group
SG_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text)

echo -e "\n🛡️  Reglas de seguridad del SG ($SG_ID):"
aws ec2 describe-security-groups --group-ids "$SG_ID" \
  --query 'SecurityGroups[].IpPermissions[*].{Protocolo: IpProtocol, Puerto: ToPort, Rango: IpRanges[*].CidrIp}' --output table

# Detalles de RDS (si tienes nombre o ID)
echo -e "\n🗄️  Buscando bases de datos RDS disponibles..."
aws rds describe-db-instances \
  --query 'DBInstances[*].{
    ID: DBInstanceIdentifier,
    Motor: Engine,
    Clase: DBInstanceClass,
    Endpoint: Endpoint.Address,
    Estado: DBInstanceStatus,
    Publica: PubliclyAccessible
  }' --output table

# Verificación de parámetros en SSM
echo -e "\n🔐 Parámetros disponibles en AWS SSM:"
aws ssm describe-parameters --query 'Parameters[*].Name' --output table | head -n 20

# IAM Roles
echo -e "\n🔐 IAM Roles disponibles asociados a EC2:"
aws iam list-instance-profiles --query 'InstanceProfiles[*].InstanceProfileName' --output table

echo -e "\n✅ Diagnóstico terminado."