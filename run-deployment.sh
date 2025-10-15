#!/bin/bash

# Complete Production Deployment Script
# Run this script on your Ubuntu 24.04 server as root

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVER_IP="193.233.19.68"
APP_DIR="/var/www/laravel"
DB_NAME="platin_escort_db"
DB_USER="platin_escort_user"
DB_PASS="kT9bL1aL0gkH"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}=== PHP Application Production Deployment ===${NC}"
echo -e "${BLUE}Server: ${SERVER_IP}${NC}"
echo -e "${BLUE}Application Directory: ${APP_DIR}${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root"
    exit 1
fi

# Step 1: System Update and Package Installation
print_status "Step 1: Updating system and installing packages..."
apt update && apt upgrade -y
apt install -y nginx php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip php8.3-intl php8.3-bcmath php8.3-sodium php8.3-opcache mysql-server unzip curl wget git ufw fail2ban

# Step 2: MySQL Configuration
print_status "Step 2: Configuring MySQL..."
systemctl start mysql
systemctl enable mysql

# Secure MySQL installation
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASS}';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Create database and user
mysql -u root -p${DB_PASS} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p${DB_PASS} -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -u root -p${DB_PASS} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -u root -p${DB_PASS} -e "FLUSH PRIVILEGES;"

# Step 3: Application Directory Setup
print_status "Step 3: Setting up application directory..."
mkdir -p ${APP_DIR}
mkdir -p ${APP_DIR}/public
mkdir -p ${APP_DIR}/logs
mkdir -p ${APP_DIR}/cache
mkdir -p ${APP_DIR}/uploads

# Step 4: PHP-FPM Configuration
print_status "Step 4: Configuring PHP-FPM..."
cat > /etc/php/8.3/fpm/pool.d/www.conf << 'EOF'
[www]
user = www-data
group = www-data
listen = /var/run/php/php8.3-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 1000
pm.process_idle_timeout = 10s

ping.path = /fpm-ping
ping.response = pong
pm.status_path = /fpm-status

access.log = /var/log/php8.3-fpm.log
access.format = "%R - %u %t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"

php_admin_value[error_log] = /var/log/php8.3-fpm-error.log
php_admin_flag[log_errors] = on

php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source
php_admin_value[open_basedir] = /var/www/laravel:/tmp:/var/tmp

php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 300
php_admin_value[post_max_size] = 20M
php_admin_value[upload_max_filesize] = 20M
php_admin_value[max_file_uploads] = 20

php_admin_value[session.gc_maxlifetime] = 3600
php_admin_value[session.cookie_httponly] = 1
php_admin_value[session.cookie_secure] = 1
php_admin_value[session.use_strict_mode] = 1

php_admin_value[opcache.enable] = 1
php_admin_value[opcache.enable_cli] = 1
php_admin_value[opcache.memory_consumption] = 128
php_admin_value[opcache.interned_strings_buffer] = 8
php_admin_value[opcache.max_accelerated_files] = 4000
php_admin_value[opcache.revalidate_freq] = 2
php_admin_value[opcache.fast_shutdown] = 1
php_admin_value[opcache.validate_timestamps] = 0

php_admin_value[realpath_cache_size] = 4096K
php_admin_value[realpath_cache_ttl] = 600

env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF

# Step 5: PHP Configuration
print_status "Step 5: Configuring PHP..."
cat > /etc/php/8.3/fpm/conf.d/99-custom.ini << 'EOF'
memory_limit = 256M
max_execution_time = 300
max_input_time = 300
post_max_size = 20M
upload_max_filesize = 20M
max_file_uploads = 20

expose_php = Off
allow_url_fopen = Off
allow_url_include = Off

session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1

opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
opcache.validate_timestamps = 0

realpath_cache_size = 4096K
realpath_cache_ttl = 600
EOF

# Step 6: Nginx Configuration
print_status "Step 6: Configuring Nginx..."
cat > /etc/nginx/sites-available/php-app << EOF
server {
    listen 80;
    listen [::]:80;
    server_name wptiklaayaz.com www.wptiklaayaz.com;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    server_tokens off;
    
    root ${APP_DIR}/public;
    index index.php index.html index.htm;
    
    access_log /var/log/nginx/php-app-access.log;
    error_log /var/log/nginx/php-app-error.log;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    client_max_body_size 20M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        try_files \$uri =404;
    }
    
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /(config|logs|cache|uploads)/ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|sql|log)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location / {
        try_files \$uri \$uri/ @php;
    }
    
    location @php {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root/index.php;
        include fastcgi_params;
        
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors on;
    }
    
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors on;
    }
    
    location /admin {
        try_files \$uri \$uri/ @php;
    }
    
    error_page 404 /404.php;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# Enable site and remove default
ln -sf /etc/nginx/sites-available/php-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Step 7: Security Configuration
print_status "Step 7: Configuring security..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'

# Configure fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
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

# Step 8: Create Environment File
print_status "Step 8: Creating environment configuration..."
cat > ${APP_DIR}/.env << EOF
APP_ENV=production
APP_DEBUG=false
APP_URL=https://wptiklaayaz.com
APP_KEY=base64:$(openssl rand -base64 32)

DB_HOST=localhost
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_CHARSET=utf8mb4

SESSION_LIFETIME=3600
CSRF_TOKEN_LIFETIME=3600
MAX_FAILED_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=30

MAX_FILE_SIZE=5242880
UPLOAD_PATH=${APP_DIR}/uploads/
LOG_PATH=${APP_DIR}/logs/
CACHE_PATH=${APP_DIR}/cache/

ADMIN_EMAIL=admin@wptiklaayaz.com
KEY_AUTH_ENABLED=true

LOG_LEVEL=error
CACHE_DRIVER=file

FORCE_HTTPS=true
SECURE_COOKIES=true
EOF

# Step 9: Set Permissions
print_status "Step 9: Setting proper permissions..."
chown -R www-data:www-data ${APP_DIR}
chmod -R 755 ${APP_DIR}
chmod -R 775 ${APP_DIR}/logs
chmod -R 775 ${APP_DIR}/cache
chmod -R 775 ${APP_DIR}/uploads

# Step 10: Test and Start Services
print_status "Step 10: Testing configuration and starting services..."
nginx -t
systemctl restart php8.3-fpm
systemctl enable php8.3-fpm
systemctl restart nginx
systemctl enable nginx
systemctl restart fail2ban
systemctl enable fail2ban

# Step 11: Create Backup Script
print_status "Step 11: Creating backup script..."
cat > /root/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"
mkdir -p $BACKUP_DIR

mysqldump -u platin_escort_user -pkT9bL1aL0gkH platin_escort_db > $BACKUP_DIR/database_$DATE.sql
tar -czf $BACKUP_DIR/application_$DATE.tar.gz /var/www/laravel

find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /root/backup.sh
echo "0 2 * * * /root/backup.sh" | crontab -

# Step 12: Create Application Files Placeholder
print_status "Step 12: Creating application structure..."
cat > ${APP_DIR}/public/index.php << 'EOF'
<?php
// Placeholder index.php - Replace with your actual application files
echo "<h1>PHP Application Server Ready!</h1>";
echo "<p>Server is configured and running.</p>";
echo "<p>Please upload your application files to /var/www/laravel/</p>";
echo "<p>Current time: " . date('Y-m-d H:i:s') . "</p>";
echo "<p>PHP Version: " . phpversion() . "</p>";
?>
EOF

# Final Status
print_status "Deployment completed successfully!"
echo ""
echo -e "${GREEN}=== DEPLOYMENT SUMMARY ===${NC}"
echo -e "Server IP: ${SERVER_IP}"
echo -e "Application Directory: ${APP_DIR}"
echo -e "Database: ${DB_NAME}"
echo -e "Database User: ${DB_USER}"
echo -e "Web Server: Nginx + PHP-FPM 8.3"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Upload your application files to ${APP_DIR}/"
echo "2. Import your database: mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < your_database.sql"
echo "3. Update ${APP_DIR}/.env with your specific settings"
echo "4. Test your application at https://wptiklaayaz.com"
echo ""
echo -e "${GREEN}Your server is ready for production!${NC}"
