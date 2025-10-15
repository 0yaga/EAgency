# Complete Deployment Instructions

## Server Information
- **IP Address**: 193.233.19.68
- **Domain**: wptiklaayaz.com
- **OS**: Ubuntu 24.04
- **Login**: root
- **Password**: kT9bL1aL0gkH

## Quick Deployment (Recommended)

### Step 1: Connect to Server
```bash
ssh root@193.233.19.68
```

### Step 2: Download and Run Deployment Script
```bash
# Create deployment directory
mkdir -p /root/deployment
cd /root/deployment

# Download the deployment script (you'll need to upload it first)
# Or copy the content from run-deployment.sh and create it manually
nano run-deployment.sh
# Paste the content from deployment/run-deployment.sh

# Make it executable and run
chmod +x run-deployment.sh
./run-deployment.sh
```

### Step 3: Upload Your Application Files
From your local machine:
```bash
# Upload your application files
scp -r /path/to/your/php/app/* root@193.233.19.68:/var/www/laravel/

# Or use rsync for better performance
rsync -av --exclude='.git' --exclude='node_modules' /path/to/your/php/app/ root@193.233.19.68:/var/www/laravel/
```

### Step 4: Import Database
```bash
# On the server
mysql -u platin_escort_user -pkT9bL1aL0gkH platin_escort_db < your_database.sql
```

### Step 5: Update Environment Configuration
```bash
# Edit the environment file
nano /var/www/laravel/.env

# Update these important settings:
# - APP_URL=https://wptiklaayaz.com
# - ADMIN_EMAIL=admin@wptiklaayaz.com
# - Any other application-specific settings
```

### Step 6: Set Final Permissions
```bash
chown -R www-data:www-data /var/www/laravel
chmod -R 755 /var/www/laravel
chmod -R 775 /var/www/laravel/logs /var/www/laravel/cache /var/www/laravel/uploads
```

### Step 7: Restart Services
```bash
systemctl restart php8.3-fpm
systemctl restart nginx
```

## Manual Deployment (Alternative)

If you prefer to run commands manually, here's the complete setup:

### 1. System Update and Package Installation
```bash
apt update && apt upgrade -y
apt install -y nginx php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip php8.3-intl php8.3-bcmath php8.3-sodium php8.3-opcache mysql-server unzip curl wget git ufw fail2ban
```

### 2. MySQL Configuration
```bash
systemctl start mysql
systemctl enable mysql

# Secure MySQL
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'kT9bL1aL0gkH';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Create database and user
mysql -u root -pkT9bL1aL0gkH -e "CREATE DATABASE IF NOT EXISTS platin_escort_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -pkT9bL1aL0gkH -e "CREATE USER IF NOT EXISTS 'platin_escort_user'@'localhost' IDENTIFIED BY 'kT9bL1aL0gkH';"
mysql -u root -pkT9bL1aL0gkH -e "GRANT ALL PRIVILEGES ON platin_escort_db.* TO 'platin_escort_user'@'localhost';"
mysql -u root -pkT9bL1aL0gkH -e "FLUSH PRIVILEGES;"
```

### 3. Application Directory Setup
```bash
mkdir -p /var/www/laravel
mkdir -p /var/www/laravel/public
mkdir -p /var/www/laravel/logs
mkdir -p /var/www/laravel/cache
mkdir -p /var/www/laravel/uploads

chown -R www-data:www-data /var/www/laravel
chmod -R 755 /var/www/laravel
chmod -R 775 /var/www/laravel/logs /var/www/laravel/cache /var/www/laravel/uploads
```

### 4. PHP-FPM Configuration
```bash
# Backup original config
cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.backup

# Create new config (copy content from php-fpm-pool.conf)
nano /etc/php/8.3/fpm/pool.d/www.conf
```

### 5. PHP Configuration
```bash
# Create custom PHP configuration
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
```

### 6. Nginx Configuration
```bash
# Create Nginx site configuration (copy content from nginx-site.conf)
nano /etc/nginx/sites-available/php-app

# Enable site
ln -sf /etc/nginx/sites-available/php-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test configuration
nginx -t
```

### 7. Security Configuration
```bash
# Configure firewall
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
```

### 8. Start Services
```bash
systemctl restart php8.3-fpm
systemctl enable php8.3-fpm
systemctl restart nginx
systemctl enable nginx
systemctl restart fail2ban
systemctl enable fail2ban
```

## SSL Setup (Optional - When You Have a Domain)

### 1. Install Certbot
```bash
apt install -y certbot python3-certbot-nginx
```

### 2. Generate SSL Certificate
```bash
# Replace 'yourdomain.com' with your actual domain
certbot --nginx -d wptiklaayaz.com -d www.wptiklaayaz.com
```

### 3. Update Environment for HTTPS
```bash
nano /var/www/laravel/.env
# Change:
# APP_URL=https://wptiklaayaz.com
# FORCE_HTTPS=true
# SECURE_COOKIES=true
```

## Application-Specific Configuration

### 1. Generate Application Key
```bash
# Generate a secure key
openssl rand -base64 32
# Add this to your .env file as APP_KEY=base64:your_generated_key
```

### 2. Database Import
```bash
# Import your existing database
mysql -u platin_escort_user -pkT9bL1aL0gkH platin_escort_db < your_database.sql
```

### 3. File Permissions
```bash
# Set proper permissions
chown -R www-data:www-data /var/www/laravel
find /var/www/laravel -type d -exec chmod 755 {} \;
find /var/www/laravel -type f -exec chmod 644 {} \;
chmod -R 775 /var/www/laravel/logs /var/www/laravel/cache /var/www/laravel/uploads
```

## Monitoring and Maintenance

### 1. Check Logs
```bash
# Application logs
tail -f /var/log/nginx/php-app-error.log
tail -f /var/log/php8.3-fpm-error.log
tail -f /var/www/laravel/logs/error.log

# System logs
journalctl -u nginx -f
journalctl -u php8.3-fpm -f
```

### 2. Check Services Status
```bash
systemctl status nginx
systemctl status php8.3-fpm
systemctl status mysql
```

### 3. Performance Monitoring
```bash
# Check PHP-FPM status
curl http://localhost/fpm-status

# Check system resources
htop
df -h
free -h
```

## Backup Script

Create a backup script for regular backups:

```bash
cat > /root/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"
mkdir -p $BACKUP_DIR

# Database backup
mysqldump -u platin_escort_user -pkT9bL1aL0gkH platin_escort_db > $BACKUP_DIR/database_$DATE.sql

# Application backup
tar -czf $BACKUP_DIR/application_$DATE.tar.gz /var/www/laravel

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /root/backup.sh

# Add to crontab for daily backups
echo "0 2 * * * /root/backup.sh" | crontab -
```

## Troubleshooting

### Common Issues

1. **502 Bad Gateway**
   ```bash
   systemctl status php8.3-fpm
   tail -f /var/log/php8.3-fpm-error.log
   ```

2. **Permission Denied**
   ```bash
   chown -R www-data:www-data /var/www/laravel
   chmod -R 755 /var/www/laravel
   ```

3. **Database Connection Error**
   ```bash
   # Check database credentials in .env
   mysql -u platin_escort_user -pkT9bL1aL0gkH platin_escort_db -e "SELECT 1;"
   ```

4. **Nginx Configuration Error**
   ```bash
   nginx -t
   systemctl restart nginx
   ```

## Security Checklist

- [x] Firewall configured (UFW)
- [x] Fail2ban enabled
- [x] PHP security settings applied
- [x] Nginx security headers configured
- [x] File permissions set correctly
- [x] Sensitive files protected
- [x] SSL certificate installed (when domain available)
- [x] Regular backups configured

## Final Notes

1. **Test Your Application**: Visit `https://wptiklaayaz.com` to verify everything is working
2. **Monitor Logs**: Check logs regularly for any issues
3. **Update Regularly**: Keep your system and packages updated
4. **Backup Regularly**: Ensure backups are working correctly
5. **Security**: Review security settings and update passwords regularly

Your PHP application should now be running securely on Ubuntu 24.04 with Nginx and PHP-FPM!

## Quick Commands Reference

```bash
# Restart services
systemctl restart nginx php8.3-fpm mysql

# Check status
systemctl status nginx php8.3-fpm mysql

# View logs
tail -f /var/log/nginx/php-app-error.log
tail -f /var/log/php8.3-fpm-error.log

# Test configuration
nginx -t

# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
htop
```
