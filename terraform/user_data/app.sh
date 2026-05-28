#!/bin/bash
set -euo pipefail

# Variables injectées par Terraform via templatefile()
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_username}"
DB_PASS="${db_password}"
APP_PORT="${app_port}"

# ---------------------------------------------------------------
# Mise à jour système + installation Node.js 20 LTS
# ---------------------------------------------------------------
dnf update -y
dnf install -y curl git

curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

# ---------------------------------------------------------------
# Installation de PM2 (process manager)
# ---------------------------------------------------------------
npm install -g pm2

# ---------------------------------------------------------------
# Création de l'utilisateur applicatif
# ---------------------------------------------------------------
useradd -m -s /bin/bash appuser

# ---------------------------------------------------------------
# Variables d'environnement de l'application
# ---------------------------------------------------------------
cat > /etc/environment.d/app.conf <<EOF
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME
PORT=$APP_PORT
NODE_ENV=production
EOF

# ---------------------------------------------------------------
# Répertoire de l'application (le code sera déployé ici)
# ---------------------------------------------------------------
mkdir -p /app
chown appuser:appuser /app

# ---------------------------------------------------------------
# Service systemd via PM2 (démarre automatiquement au boot)
# ---------------------------------------------------------------
su - appuser -c "pm2 startup systemd -u appuser --hp /home/appuser" | tail -1 | bash || true

echo "User data script completed - instance ready for app deployment"
