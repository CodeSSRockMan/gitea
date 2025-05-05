#!/bin/bash

# CONFIGURACIÓN
INSTANCE_ID="i-005c76a502d3677b1"  # <-- Cambia por tu instancia EC2 real
VPC_ID=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].VpcId" \
  --output text)

echo "📡 Obteniendo los Security Groups de la VPC $VPC_ID..."

# OBTENER LISTA DE SGs
mapfile -t SG_LIST < <(aws ec2 describe-security-groups \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query "SecurityGroups[*].[GroupId,GroupName]" \
  --output text)

[[ ${#SG_LIST[@]} -eq 0 ]] && echo "❌ No se encontraron Security Groups en la VPC $VPC_ID" && exit 1

# MOSTRAR OPCIONES
echo -e "\n🔐 Security Groups disponibles:"
for i in "${!SG_LIST[@]}"; do
  echo "  $((i+1)). ${SG_LIST[$i]}"
done

# SELECCIÓN
echo ""
read -p "👉 Ingresa el número del SG que quieres asignar a la instancia EC2 ($INSTANCE_ID): " SELECTION

[[ "$SELECTION" =~ ^[0-9]+$ ]] && 
[[ "$SELECTION" -ge 1 ]] && 
[[ "$SELECTION" -le ${#SG_LIST[@]} ]] || {
  echo "❌ Selección inválida"
  exit 1
}

# OBTENER ID del SG elegido
SG_ID=$(echo "${SG_LIST[$((SELECTION-1))]}" | awk '{print $1}')
SG_NAME=$(echo "${SG_LIST[$((SELECTION-1))]}" | awk '{print $2}')

echo -e "\n🔄 Asignando Security Group '$SG_NAME' ($SG_ID) a la instancia $INSTANCE_ID..."

aws ec2 modify-instance-attribute \
  --instance-id "$INSTANCE_ID" \
  --groups "$SG_ID" &&
  echo "✅ SG actualizado exitosamente" ||
  echo "❌ Error al actualizar el SG"
