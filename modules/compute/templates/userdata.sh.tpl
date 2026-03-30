#!/bin/bash
# ==============================================================================
# Application Server Bootstrap Script
# ==============================================================================
# This script is rendered via Terraform templatefile() — all variables are
# injected at plan time. No hardcoded credentials exist in this template.
# ==============================================================================

set -euo pipefail

exec > >(tee /var/log/userdata.log) 2>&1
echo "[$(date)] Starting application server setup..."

# --- System Updates ---
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# --- Install MySQL Client (connects to RDS, not local MySQL server) ---
apt-get install -y mysql-client-core-8.0

# --- Install common utilities ---
apt-get install -y \
  curl \
  wget \
  unzip \
  jq \
  net-tools \
  htop

# --- Write database connection configuration ---
mkdir -p /etc/app
cat > /etc/app/db-config.env <<'DBCONFIG'
DB_HOST=${db_endpoint}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASS=${db_password}
ENVIRONMENT=${environment}
DBCONFIG

chmod 600 /etc/app/db-config.env

# --- Verify database connectivity ---
echo "[$(date)] Testing database connectivity to ${db_endpoint}..."
if mysql -h "${db_endpoint}" -u "${db_username}" -p"${db_password}" -e "SELECT 1;" 2>/dev/null; then
  echo "[$(date)] ✅ Database connection successful"
else
  echo "[$(date)] ⚠️  Database connection failed (RDS may still be initializing)"
fi

echo "[$(date)] ✅ Application server setup complete"
