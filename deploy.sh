#!/bin/bash

# Production Deployment Script for PHP Application
# Ubuntu 24.04 + Nginx + PHP-FPM + MySQL

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="193.233.19.68"
APP_DIR="/var/www/laravel"
DOMAIN="193.233.19.68"  # Replace with your domain when available
DB_NAME="platin_escort_db"
DB_USER="platin_escort_user"

echo -e "${BLUE}Starting deployment for PHP Application on Ubuntu 24.04${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Update system packages
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
print_status "Installing required packages..."
apt install -y nginx php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip php8.3-intl php8.3-bcmath php8.3-sodium php8.3-opcache mysql-server unzip curl wget git ufw fail2ban

# Configure MySQL
print_status "Configuring MySQL..."
systemctl start mysql
systemctl enable mysql

# Secure MySQL installation
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'kT9bL1aL0gkH';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Create database and user
print_status "Creating database and user..."
mysql -u root -pkT9bL1aL0gkH -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -pkT9bL1aL0gkH -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY 'kT9bL1aL0gkH';"
mysql -u root -pkT9bL1aL0gkH -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -u root -pkT9bL1aL0gkH -e "FLUSH PRIVILEGES;"

# Create application directory
print_status "Creating application directory..."
mkdir -p ${APP_DIR}
mkdir -p ${APP_DIR}/public
mkdir -p ${APP_DIR}/logs
mkdir -p ${APP_DIR}/cache
mkdir -p ${APP_DIR}/uploads

# Set proper permissions
print_status "Setting proper permissions..."
chown -R www-data:www-data ${APP_DIR}
chmod -R 755 ${APP_DIR}
chmod -R 775 ${APP_DIR}/logs
chmod -R 775 ${APP_DIR}/cache
chmod -R 775 ${APP_DIR}/uploads

# Configure PHP-FPM
print_status "Configuring PHP-FPM..."
cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.backup
cp deployment/php-fpm-pool.conf /etc/php/8.3/fpm/pool.d/www.conf

# Configure PHP
print_status "Configuring PHP..."
cat > /etc/php/8.3/fpm/conf.d/99-custom.ini << EOF
; Custom PHP configuration for production
memory_limit = 256M
max_execution_time = 300
max_input_time = 300
post_max_size = 20M
upload_max_filesize = 20M
max_file_uploads = 20

; Security
expose_php = Off
allow_url_fopen = Off
allow_url_include = Off

; Session security
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1

; OPcache
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
opcache.validate_timestamps = 0

; Realpath cache
realpath_cache_size = 4096K
realpath_cache_ttl = 600
EOF

# Configure Nginx
print_status "Configuring Nginx..."
cp deployment/nginx-site.conf /etc/nginx/sites-available/php-app
ln -sf /etc/nginx/sites-available/php-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Start and enable services
print_status "Starting and enabling services..."
systemctl restart php8.3-fpm
systemctl enable php8.3-fpm
systemctl restart nginx
systemctl enable nginx

# Configure firewall
print_status "Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 3306/tcp  # MySQL (if needed for remote access)

# Configure fail2ban
print_status "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
EOF

systemctl restart fail2ban
systemctl enable fail2ban

# Create deployment completion script
print_status "Creating deployment completion script..."
cat > ${APP_DIR}/complete_deployment.sh << 'EOF'
#!/bin/bash

# Complete deployment by copying application files and configuring environment

echo "Copying application files..."
# Copy your application files here
# rsync -av --exclude='.git' --exclude='node_modules' /path/to/your/app/ ${APP_DIR}/

echo "Setting up environment file..."
# Copy and configure .env file
# cp deployment/env.production ${APP_DIR}/.env

echo "Importing database..."
# Import your database
# mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < database.sql

echo "Setting final permissions..."
chown -R www-data:www-data ${APP_DIR}
chmod -R 755 ${APP_DIR}
chmod -R 775 ${APP_DIR}/logs ${APP_DIR}/cache ${APP_DIR}/uploads

echo "Restarting services..."
systemctl restart php8.3-fpm
systemctl restart nginx

echo "Deployment completed!"
echo "Your application should now be accessible at http://${SERVER_IP}"
EOF

chmod +x ${APP_DIR}/complete_deployment.sh

print_status "Deployment script completed!"
print_warning "Next steps:"
echo "1. Copy your application files to ${APP_DIR}"
echo "2. Copy deployment/env.production to ${APP_DIR}/.env and configure it"
echo "3. Import your database: mysql -u ${DB_USER} -pkT9bL1aL0gkH ${DB_NAME} < database.sql"
echo "4. Run: ${APP_DIR}/complete_deployment.sh"
echo "5. Test your application at http://${SERVER_IP}"

print_status "Server is ready for application deployment!"
