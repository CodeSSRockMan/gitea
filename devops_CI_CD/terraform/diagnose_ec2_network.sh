#!/bin/bash

INSTANCE_ID="$1"

if [ -z "$INSTANCE_ID" ]; then
  echo "Uso: $0 <INSTANCE_ID>"
  exit 1
fi

echo "🔍 Diagnóstico resumido para EC2 $INSTANCE_ID"
echo "-----------------------------------------------"

# Obtener info básica de instancia
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].{
    Estado: State.Name,
    IP_Publica: PublicIpAddress,
    Subnet: SubnetId,
    VPC: VpcId,
    SG: SecurityGroups[0].GroupId
  }' --output json

SUBNET_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].SubnetId' --output text)
SG_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)

# Tabla de ruteo asociada
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
  --query 'RouteTables[0].RouteTableId' --output text)

echo -e "\n🛣️ Tabla de ruteo de la Subnet: $ROUTE_TABLE_ID"
aws ec2 describe-route-tables --route-table-ids "$ROUTE_TABLE_ID" \
  --query 'RouteTables[0].Routes[*].{Destino: DestinationCidrBlock, Target: GatewayId}' \
  --output table

# Reglas SG (ingress y egress resumido)
echo -e "\n🛡️ Reglas de entrada (ingress) del SG $SG_ID:"
aws ec2 describe-security-groups --group-ids "$SG_ID" \
  --query 'SecurityGroups[0].IpPermissions[*].{Puerto: FromPort, Protocolo: IpProtocol, Rango: IpRanges[0].CidrIp}' \
  --output table

echo -e "\n📤 Reglas de salida (egress):"
aws ec2 describe-security-groups --group-ids "$SG_ID" \
  --query 'SecurityGroups[0].IpPermissionsEgress[*].{Puerto: FromPort, Protocolo: IpProtocol, Rango: IpRanges[0].CidrIp}' \
  --output table

echo -e "\n✅ Diagnóstico completo. Verifica que:"
echo " - Hay una ruta hacia un Internet Gateway (igw-*)"
echo " - Las reglas ingress permiten puertos 80 y 8080 desde 0.0.0.0/0"
echo " - Las reglas egress permiten salida al menos en el puerto 443 o todos (-1)"
