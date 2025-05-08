#!/bin/bash
set -e

echo "[INFO] Installing dependencies..."
sudo apt update
sudo apt install -y wget git

echo "[INFO] Checking if user 'git' exists..."
id "git" &>/dev/null || {
  echo "[INFO] Creating user 'git'..."
  sudo adduser \
    --system \
    --shell /bin/bash \
    --gecos 'Git Version Control' \
    --group \
    --disabled-password \
    --home /home/git \
    git
}

echo "[INFO] Creating required directories if missing..."
for dir in /var/lib/gitea/custom /var/lib/gitea/data /var/lib/gitea/log /etc/gitea; do
  [ -d "$dir" ] && echo "[OK] Directory $dir already exists." || {
    echo "[INFO] Creating directory $dir"
    sudo mkdir -p "$dir"
  }
done

echo "[INFO] Setting permissions..."
sudo chown -R git:git /var/lib/gitea/
sudo chmod -R 750 /var/lib/gitea/
sudo chown root:git /etc/gitea
sudo chmod 770 /etc/gitea

echo "[INFO] Checking if Gitea binary is present..."
[ -f "/usr/local/bin/gitea" ] && echo "[OK] Gitea binary already exists." || {
  echo "[INFO] Downloading Gitea binary..."
  wget -O gitea https://dl.gitea.com/gitea/1.23.7/gitea-1.23.7-linux-amd64
  chmod +x gitea
  sudo mv gitea /usr/local/bin/gitea
}

echo "[INFO] Starting Gitea in web installation mode..."
sudo -u git GITEA_WORK_DIR=/var/lib/gitea /usr/local/bin/gitea web
