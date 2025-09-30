# Stage 1 - Build Frontend (Vite with npm)
FROM node:22.14.0 AS frontend
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies using npm
RUN npm ci --only=production || npm install

# Copy source files
COPY . .

# Build frontend assets
RUN npm run build

# Stage 2 - Backend (Laravel + PHP + Composer + Nginx)
FROM php:8.1.25-fpm AS backend

# Install system dependencies including nginx
RUN apt-get update && apt-get install -y \
    git curl unzip libpq-dev libonig-dev libzip-dev zip nginx \
    && docker-php-ext-install pdo pdo_mysql mbstring zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2.8.9 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy composer files first for better caching
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy application files
COPY . .

# Copy built frontend from Stage 1
COPY --from=frontend /app/public/dist ./public/dist

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Configure nginx for Laravel
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /var/www/html/public; \
    index index.php; \
    \
    location / { \
        try_files $uri $uri/ /index.php?$query_string; \
    } \
    \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_index index.php; \
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name; \
        include fastcgi_params; \
    } \
    \
    location ~ /\.ht { \
        deny all; \
    } \
}' > /etc/nginx/sites-available/default

# Create startup script
RUN echo '#!/bin/bash \
set -e \
\
# Start PHP-FPM in background \
php-fpm -D \
\
# Start nginx in foreground \
nginx -g "daemon off;"' > /start.sh \
    && chmod +x /start.sh

# Expose port 80
EXPOSE 80

# Health check for Render
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start the application
CMD ["/start.sh"]
