#!/bin/bash
set -e

echo "==== 🌍 GCP: Verificación de credenciales ===="

if command -v gcloud &>/dev/null; then
  echo "[✓] gcloud instalado"

  echo -n "[*] Usuario activo (gcloud auth list): "
  gcloud auth list --format="value(account)" 2>/dev/null | grep . || echo "(no configurado)"

  echo -n "[*] Proyecto activo: "
  gcloud config get-value project 2>/dev/null || echo "(no configurado)"

  echo -n "[*] Cuenta de servicio impersonada: "
  gcloud config get-value impersonate_service_account 2>/dev/null || echo "(no definida)"

  echo -n "[*] Variable GOOGLE_APPLICATION_CREDENTIALS: "
  echo "${GOOGLE_APPLICATION_CREDENTIALS:-"(no definida)"}"
else
  echo "[!] gcloud no está instalado"
fi

echo ""
echo "==== 🔐 GCP: Roles IAM asignados al usuario activo ===="

if [[ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
  echo "[!] Variable GOOGLE_APPLICATION_CREDENTIALS no definida, se usará la cuenta autenticada por gcloud."
  active_account=$(gcloud auth list --format="value(account)" | head -n 1)
else
  echo "[*] Usando cuenta del JSON de GOOGLE_APPLICATION_CREDENTIALS"
  active_account=$(jq -r .client_email < "$GOOGLE_APPLICATION_CREDENTIALS")
fi

echo "[*] Cuenta analizada: $active_account"
echo "[*] Roles IAM asignados en el proyecto actual:"

gcloud projects get-iam-policy "$(gcloud config get-value project 2>/dev/null)" \
  --flatten="bindings[].members" \
  --format='table(bindings.role)' \
  --filter="bindings.members:${active_account}" 2>/dev/null || echo "[!] Error consultando políticas IAM"





echo ""
echo "==== ☁️ AWS: Verificación de credenciales ===="

if command -v aws &>/dev/null; then
  echo "[✓] aws instalado"

  echo -n "[*] Perfil activo: "
  echo "${AWS_PROFILE:-default}"

  echo -n "[*] Región activa: "
  echo "${AWS_REGION:-$AWS_DEFAULT_REGION}"

  echo -n "[*] Variables de entorno:"
  echo ""
  env | grep ^AWS_ || echo "(sin variables AWS definidas)"

  echo "[*] Probar STS get-caller-identity:"
  aws sts get-caller-identity --output table 2>/dev/null || echo "(falló o sin credenciales)"
else
  echo "[!] aws CLI no está instalado"
fi
