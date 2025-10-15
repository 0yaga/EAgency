# PHP Application Deployment Guide

## Production Deployment on Ubuntu 24.04 with Nginx + PHP-FPM + MySQL

This guide provides a complete deployment setup for your PHP application on Ubuntu 24.04 with Nginx, PHP-FPM, and MySQL.

### Server Information
- **IP Address**: 193.233.19.68
- **OS**: Ubuntu 24.04
- **Login**: root
- **Password**: kT9bL1aL0gkH

### Prerequisites
- Ubuntu 24.04 server with root access
- Domain name (optional, for SSL setup)
- Application files ready for deployment

## Quick Deployment

### 1. Initial Server Setup

Connect to your server and run the deployment script:

```bash
# Connect to server
ssh root@193.233.19.68

# Download and run deployment script
wget https://raw.githubusercontent.com/your-repo/deployment/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

### 2. Application Deployment

After the server setup is complete:

```bash
# Copy your application files to the server
scp -r /path/to/your/app/* root@193.233.19.68:/var/www/laravel/

# Or use rsync for better performance
rsync -av --exclude='.git' --exclude='node_modules' /path/to/your/app/ root@193.233.19.68:/var/www/laravel/
```

### 3. Environment Configuration

```bash
# Copy environment file
scp deployment/env.production root@193.233.19.68:/var/www/laravel/.env

# Edit the environment file
ssh root@193.233.19.68
nano /var/www/laravel/.env
```

Update the following variables in `.env`:
- `APP_KEY`: Generate a secure 32-character key
- `DB_PASS`: Set your database password
- `ADMIN_EMAIL`: Set your admin email
- `APP_URL`: Update with your domain when available

### 4. Database Setup

```bash
# Import your database
mysql -u platin_escort_user -pkT9bL1aL0gkH platin_escort_db < database.sql

# Or create tables manually if you have SQL files
mysql -u platin_escort_user -pkT9bL1aL0gkH platin_escort_db < database.sql
```

### 5. Final Configuration

```bash
# Run the completion script
/var/www/laravel/complete_deployment.sh
```

## Manual Deployment Steps

If you prefer to run commands manually:

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
mysql_secure_installation

# Create database and user
mysql -u root -p
```

```sql
CREATE DATABASE platin_escort_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'platin_escort_user'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON platin_escort_db.* TO 'platin_escort_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
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
# Copy the provided PHP-FPM pool configuration
cp deployment/php-fpm-pool.conf /etc/php/8.3/fpm/pool.d/www.conf

# Configure PHP
cat > /etc/php/8.3/fpm/conf.d/99-custom.ini << EOF
memory_limit = 256M
max_execution_time = 300
post_max_size = 20M
upload_max_filesize = 20M
expose_php = Off
opcache.enable = 1
opcache.memory_consumption = 128
EOF

systemctl restart php8.3-fpm
```

### 5. Nginx Configuration

```bash
# Copy the provided Nginx configuration
cp deployment/nginx-site.conf /etc/nginx/sites-available/php-app
ln -sf /etc/nginx/sites-available/php-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t
systemctl restart nginx
```

### 6. Security Configuration

```bash
# Configure firewall
ufw enable
ufw allow ssh
ufw allow 'Nginx Full'

# Configure fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

## SSL Certificate Setup (Optional)

If you have a domain name, set up SSL with Let's Encrypt:

```bash
# Update domain in ssl-setup.sh
nano deployment/ssl-setup.sh

# Run SSL setup
chmod +x deployment/ssl-setup.sh
./deployment/ssl-setup.sh
```

## Application-Specific Configuration

### 1. Generate Application Key

```bash
# Generate a secure application key
openssl rand -base64 32
```

Add this key to your `.env` file as `APP_KEY`.

### 2. Database Import

```bash
# Import your existing database
mysql -u platin_escort_user -p platin_escort_db < database.sql
```

### 3. File Permissions

```bash
# Set proper permissions for your application
chown -R www-data:www-data /var/www/laravel
find /var/www/laravel -type d -exec chmod 755 {} \;
find /var/www/laravel -type f -exec chmod 644 {} \;
chmod -R 775 /var/www/laravel/logs /var/www/laravel/cache /var/www/laravel/uploads
```

## Monitoring and Maintenance

### 1. Log Monitoring

```bash
# Check application logs
tail -f /var/log/nginx/php-app-error.log
tail -f /var/log/php8.3-fpm-error.log
tail -f /var/www/laravel/logs/error.log
```

### 2. Performance Monitoring

```bash
# Check PHP-FPM status
curl http://localhost/fpm-status

# Check system resources
htop
df -h
free -h
```

### 3. Backup Script

Create a backup script:

```bash
cat > /root/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"
mkdir -p $BACKUP_DIR

# Database backup
mysqldump -u platin_escort_user -p platin_escort_db > $BACKUP_DIR/database_$DATE.sql

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

1. **502 Bad Gateway**: Check PHP-FPM status
   ```bash
   systemctl status php8.3-fpm
   ```

2. **Permission Denied**: Check file permissions
   ```bash
   ls -la /var/www/laravel
   ```

3. **Database Connection Error**: Verify database credentials in `.env`

4. **SSL Issues**: Check certificate validity
   ```bash
   certbot certificates
   ```

### Performance Optimization

1. **Enable OPcache**: Already configured in PHP settings
2. **Enable Gzip**: Already configured in Nginx
3. **Static File Caching**: Already configured in Nginx
4. **Database Optimization**: Regular maintenance recommended

## Security Checklist

- [x] Firewall configured (UFW)
- [x] Fail2ban enabled
- [x] PHP security settings applied
- [x] Nginx security headers configured
- [x] File permissions set correctly
- [x] Sensitive files protected
- [x] SSL certificate installed (if domain available)
- [x] Regular backups configured

## Support

For issues or questions:
1. Check the logs first
2. Verify configuration files
3. Test individual components
4. Review security settings

Your PHP application should now be running securely on Ubuntu 24.04 with Nginx and PHP-FPM!
