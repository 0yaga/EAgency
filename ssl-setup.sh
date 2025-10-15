#!/bin/bash

# SSL Certificate Setup with Let's Encrypt (Certbot)
# Run this script after your domain is pointing to the server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
DOMAIN="wptiklaayaz.com"
EMAIL="admin@wptiklaayaz.com"

echo -e "${BLUE}Setting up SSL certificate with Let's Encrypt${NC}"

# Check if domain is provided
# Domain is now configured for wptiklaayaz.com

# Install Certbot
print_status "Installing Certbot..."
apt update
apt install -y certbot python3-certbot-nginx

# Stop Nginx temporarily
print_status "Stopping Nginx for certificate generation..."
systemctl stop nginx

# Generate SSL certificate
print_status "Generating SSL certificate for ${DOMAIN}..."
certbot certonly --standalone -d ${DOMAIN} --email ${EMAIL} --agree-tos --non-interactive

# Update Nginx configuration for HTTPS
print_status "Updating Nginx configuration for HTTPS..."
cat > /etc/nginx/sites-available/php-app << EOF
# Nginx Configuration for PHP Application with SSL
# Production-ready configuration with security headers and optimization

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN};
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/${DOMAIN}/chain.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Hide Nginx version
    server_tokens off;
    
    # Document root
    root /var/www/laravel/public;
    index index.php index.html index.htm;
    
    # Logging
    access_log /var/log/nginx/php-app-access.log;
    error_log /var/log/nginx/php-app-error.log;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    # Client settings
    client_max_body_size 20M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    
    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        try_files \$uri =404;
    }
    
    # Security: Block access to sensitive files
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
    
    # Main application routing
    location / {
        try_files \$uri \$uri/ @php;
    }
    
    # PHP processing
    location @php {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root/index.php;
        include fastcgi_params;
        
        # FastCGI settings
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors on;
    }
    
    # Direct PHP file processing
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # FastCGI settings
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_intercept_errors on;
    }
    
    # Admin panel protection (optional - add IP restrictions)
    location /admin {
        # Uncomment and add your IP for admin access restriction
        # allow 192.168.1.0/24;
        # allow YOUR_IP_ADDRESS;
        # deny all;
        
        try_files \$uri \$uri/ @php;
    }
    
    # Error pages
    error_page 404 /404.php;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# Test Nginx configuration
print_status "Testing Nginx configuration..."
nginx -t

# Start Nginx
print_status "Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Set up automatic certificate renewal
print_status "Setting up automatic certificate renewal..."
cat > /etc/cron.d/certbot << EOF
# Renew Let's Encrypt certificates twice daily
0 */12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

# Update environment file for HTTPS
print_status "Updating environment configuration for HTTPS..."
sed -i 's/APP_URL=http:/APP_URL=https:/' /var/www/laravel/.env
sed -i 's/FORCE_HTTPS=false/FORCE_HTTPS=true/' /var/www/laravel/.env
sed -i 's/SECURE_COOKIES=false/SECURE_COOKIES=true/' /var/www/laravel/.env

print_status "SSL setup completed!"
print_warning "Your application is now accessible at: https://${DOMAIN}"
print_warning "HTTP traffic will be automatically redirected to HTTPS"

# Test SSL configuration
print_status "Testing SSL configuration..."
curl -I https://${DOMAIN} || print_warning "SSL test failed - please check your domain DNS settings"
