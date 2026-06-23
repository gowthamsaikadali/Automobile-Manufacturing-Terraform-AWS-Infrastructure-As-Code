#!/bin/bash
###############################################################################
# EC2 user_data — runs ONCE at first boot, as root.
# Matched to gowthamsaikadali/Automobile-Manufacturing-Application:
#   config.py  -> reads DATABASE_URL via python-dotenv from .env, falls back
#                 to SQLite if DATABASE_URL is unset (we always set it)
#   app.py     -> create_app() factory, module-level `app = create_app()`
#   wsgi.py    -> `from app import app`  => gunicorn target is wsgi:app
#   routes.py  -> exposes GET /health (DB probe, optional X-Health-Token)
#   seed.py    -> supports --admin-only (creates/updates admin user only,
#                 safe to run on every instance without duplicating data)
#
# Fully automates: package install -> clone repo -> venv + pip install ->
#                   pull DB creds from Secrets Manager -> write .env ->
#                   seed admin user -> gunicorn (systemd) -> nginx reverse
#                   proxy -> app live on port $${app_port} behind the ALB.
#
# Logs of this whole script land in /var/log/user-data.log on the instance,
# and are also forwarded to CloudWatch via the IAM role attached to this EC2.
###############################################################################
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

APP_DIR="/opt/forgepoint"
APP_USER="appuser"
GIT_REPO_URL="${git_repo_url}"
GIT_BRANCH="${git_branch}"
APP_PORT="${app_port}"
DB_SECRET_ARN="${db_secret_arn}"
AWS_REGION="${aws_region}"

# Gunicorn binds to an internal-only loopback port. Nginx listens on $APP_PORT
# (the port the ALB target group forwards to) and reverse-proxies to gunicorn.
GUNICORN_INTERNAL_PORT=8001

echo ">>> Updating system and installing base packages"
apt-get update -y
apt-get install -y python3 python3-venv python3-pip python3-dev build-essential \
  git nginx jq unzip curl libpq-dev default-libmysqlclient-dev pkg-config

echo ">>> Installing AWS CLI v2 (for Secrets Manager fetch)"
if ! command -v aws &> /dev/null; then
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
fi

echo ">>> Creating app user"
id -u $APP_USER &>/dev/null || useradd -m -s /bin/bash $APP_USER

echo ">>> Cloning application repository"
rm -rf $APP_DIR
git clone --branch "$GIT_BRANCH" --depth 1 "$GIT_REPO_URL" $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR

echo ">>> Creating Python virtual environment and installing requirements"
sudo -u $APP_USER python3 -m venv $APP_DIR/venv
sudo -u $APP_USER $APP_DIR/venv/bin/pip install --upgrade pip
sudo -u $APP_USER $APP_DIR/venv/bin/pip install -r $APP_DIR/requirements.txt
# requirements.txt already pins gunicorn==22.0.0, psycopg2-binary, and PyMySQL —
# no extra installs needed here, unlike a generic template.

echo ">>> Fetching DB credentials from Secrets Manager"
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --region "$AWS_REGION" --query SecretString --output text)
DATABASE_URL=$(echo "$SECRET_JSON" | jq -r '.database_url')

echo ">>> Writing .env file for the Flask app (read by config.py via python-dotenv)"
# Variable names below match config.py exactly: SECRET_KEY, DATABASE_URL,
# FLASK_DEBUG, FLASK_ENV, SESSION_COOKIE_SECURE, DEFAULT_ADMIN_USERNAME/PASSWORD.
cat > $APP_DIR/.env <<EOF
DATABASE_URL=$DATABASE_URL
FLASK_ENV=production
FLASK_DEBUG=false
SECRET_KEY=$(openssl rand -hex 32)
SESSION_COOKIE_SECURE=false
APP_NAME=Automobile Manufacturing Dashboard
LOG_LEVEL=INFO
DEFAULT_ADMIN_USERNAME=admin
# <<< CHANGE ME: Set a secure password for the admin user, or use TF_VAR_admin_password env var
DEFAULT_ADMIN_PASSWORD=Admin@123
EOF
# IMPORTANT: HEALTHCHECK_TOKEN is intentionally left UNSET here. Per
# .env.production.example, routes.py only enforces the X-Health-Token header
# on /health when this variable is set. The ALB health check cannot send
# custom headers, so setting this would lock the ALB out of /health and every
# instance would be marked unhealthy forever. Leave it blank for ALB-checked
# deployments, or set it manually later and add a custom header rule if you
# put CloudFront or another header-injecting layer in front of the ALB.
chown $APP_USER:$APP_USER $APP_DIR/.env
chmod 600 $APP_DIR/.env

# NOTE on SESSION_COOKIE_SECURE: set to "true" once you attach an ACM
# certificate (var.certificate_arn) and traffic to the ALB is HTTPS, since
# secure cookies are dropped by browsers over plain HTTP. ProxyFix in app.py
# already trusts the ALB's X-Forwarded-Proto header, so this is the only
# change needed when you add a certificate.

echo ">>> Saving admin credentials to Secrets Manager for retrieval"
# Store the admin password in Secrets Manager so you can retrieve it
# from the AWS console instead of reading instance logs.
ADMIN_PASSWORD=$(grep DEFAULT_ADMIN_PASSWORD $APP_DIR/.env | cut -d= -f2-)
aws secretsmanager put-secret-value \
  --secret-id "$DB_SECRET_ARN" \
  --region "$AWS_REGION" \
  --secret-string "$(echo "$SECRET_JSON" | jq --arg pw "$ADMIN_PASSWORD" '. + {app_admin_username: "admin", app_admin_password: $pw}')" \
  || echo "Could not update secret with admin password — check it in /var/log/user-data.log instead (this log is not world-readable)"

echo ">>> Initializing database schema and admin user"
# models.py defines db.Model classes; seed.py's seed_database() calls
# db.create_all() itself, so no separate `flask db upgrade` step is required
# even though Flask-Migrate is wired in app.py. --admin-only avoids reseeding
# demo data on every new ASG instance.
sudo -u $APP_USER bash -c "cd $APP_DIR && source venv/bin/activate && python seed.py --admin-only" \
  || echo "seed.py --admin-only failed — check DB connectivity, continuing so nginx/gunicorn still start"

echo ">>> Installing gunicorn systemd service from repo's deploy/ folder"
if [ -f "$APP_DIR/deploy/gunicorn.service" ]; then
  cp "$APP_DIR/deploy/gunicorn.service" /etc/systemd/system/gunicorn.service
else
  echo "ERROR: $APP_DIR/deploy/gunicorn.service not found in repo — generating a matching fallback"
  cat > /etc/systemd/system/gunicorn.service <<EOF
[Unit]
Description=Gunicorn instance for Automobile Manufacturing Dashboard
After=network.target

[Service]
User=$APP_USER
Group=www-data
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:$GUNICORN_INTERNAL_PORT wsgi:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
fi

echo ">>> Installing nginx config from repo's deploy/ folder"
if [ -f "$APP_DIR/deploy/nginx.conf" ]; then
  cp "$APP_DIR/deploy/nginx.conf" /etc/nginx/sites-available/forgepoint
else
  echo "ERROR: $APP_DIR/deploy/nginx.conf not found in repo — generating a matching fallback"
  cat > /etc/nginx/sites-available/forgepoint <<EOF
server {
    listen $APP_PORT;
    server_name _;

    location /static/ {
        alias $APP_DIR/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:$GUNICORN_INTERNAL_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}
EOF
fi

ln -sf /etc/nginx/sites-available/forgepoint /etc/nginx/sites-enabled/forgepoint
rm -f /etc/nginx/sites-enabled/default
nginx -t

echo ">>> Enabling and starting services"
systemctl daemon-reload
systemctl enable gunicorn
systemctl restart gunicorn
systemctl enable nginx
systemctl restart nginx

echo ">>> Installing CloudWatch agent for log shipping"
curl -s https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -o /tmp/cw-agent.deb
dpkg -i -E /tmp/cw-agent.deb || true

echo ">>> Verifying app responds on /health locally before finishing"
sleep 5
curl -sf "http://127.0.0.1:$APP_PORT/health" && echo " — /health OK" || echo "WARNING: /health did not return success yet, check 'systemctl status gunicorn' and /var/log/user-data.log"

echo ">>> user_data script complete"
