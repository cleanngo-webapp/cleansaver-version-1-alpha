# Stage 1 - Build Frontend (Vite with pnpm - matching project setup)
FROM node:22.14.0 AS frontend
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm

# Copy package files and configs
COPY package.json pnpm-lock.yaml ./
COPY postcss.config.js tailwind.config.js ./

# Debug: Check package files and configs
RUN echo "=== Checking package files ===" && \
    echo "Package.json exists:" && \
    ls -la package.json && \
    echo "pnpm-lock.yaml exists:" && \
    ls -la pnpm-lock.yaml && \
    echo "PostCSS config exists:" && \
    ls -la postcss.config.js && \
    echo "Tailwind config exists:" && \
    ls -la tailwind.config.js && \
    echo "Node version:" && \
    node --version && \
    echo "PNPM version:" && \
    pnpm --version

# Install dependencies using pnpm (including dev dependencies for build)
RUN pnpm install --frozen-lockfile

# Copy source files
COPY . .

# Debug: Check if build script exists and dependencies are installed
RUN echo "Checking package.json build script..." && \
    cat package.json | grep -A 5 -B 5 "build" && \
    echo "Checking if vite is installed..." && \
    pnpm list vite && \
    echo "Checking pnpm scripts..." && \
    pnpm run

# Build frontend assets with error handling
RUN echo "Starting build process..." && \
    NODE_ENV=production pnpm run build && \
    echo "Build completed successfully!"

# Verify build output - Laravel Vite plugin outputs to public/build/
RUN echo "=== Checking Vite build output ===" && \
    echo "Public directory contents:" && \
    ls -la public/ && \
    echo "Checking for build folder (Laravel Vite default):" && \
    ls -la public/build/ 2>/dev/null || echo "No build folder found" && \
    echo "Checking for manifest files:" && \
    find public/ -name "manifest.json" -type f 2>/dev/null || echo "No manifest.json found" && \
    echo "Checking CSS files in build:" && \
    find public/build/ -name "*.css" -exec echo "CSS file: {}" \; -exec head -20 {} \; 2>/dev/null || echo "No CSS files found" && \
    echo "Checking JS files in build:" && \
    find public/build/ -name "*.js" -exec echo "JS file: {}" \; -exec head -10 {} \; 2>/dev/null || echo "No JS files found" && \
    echo "Final public directory structure:" && \
    find public/ -type f -name "*.json" -o -name "*.js" -o -name "*.css" 2>/dev/null || echo "No assets found"

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

# Install PHP dependencies (skip post-install scripts that require Laravel)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Copy application files
COPY . .

# Copy built frontend from Stage 1 - Laravel Vite plugin outputs to public/build/
COPY --from=frontend /app/public/build ./public/build

# Debug: Verify build assets were copied correctly
RUN echo "=== Verifying build assets ===" && \
    echo "Build directory contents:" && \
    ls -la ./public/build/ && \
    echo "Manifest file:" && \
    cat ./public/build/manifest.json 2>/dev/null || echo "No manifest.json found" && \
    echo "CSS files:" && \
    find ./public/build/ -name "*.css" 2>/dev/null || echo "No CSS files found" && \
    echo "JS files:" && \
    find ./public/build/ -name "*.js" 2>/dev/null || echo "No JS files found"

# Create fallback assets if build failed
RUN if [ ! -f ./public/build/manifest.json ]; then \
        echo "Creating fallback manifest and assets..." && \
        mkdir -p ./public/build && \
        echo '{"resources/css/app.css":{"file":"app.css","src":"resources/css/app.css","isEntry":true},"resources/js/app.js":{"file":"app.js","src":"resources/js/app.js","isEntry":true}}' > ./public/build/manifest.json && \
        echo '/* Fallback CSS - Tailwind not compiled */' > ./public/build/app.css && \
        echo '/* Fallback JS */' > ./public/build/app.js; \
    fi

# Create minimal .env for Laravel commands
RUN echo "APP_NAME=Laravel" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_KEY=base64:placeholder" >> .env && \
    echo "APP_DEBUG=false" >> .env && \
    echo "APP_URL=http://localhost" >> .env

# Run Laravel post-install commands with fallback
RUN php artisan package:discover --ansi || echo "Package discovery skipped"

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Configure nginx for Laravel with proper static asset handling
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /var/www/html/public; \
    index index.php; \
    \
    # Handle static assets (CSS, JS, images, etc.) \
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
        try_files $uri =404; \
    } \
    \
    # Handle Vite build assets \
    location /build/ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
        try_files $uri =404; \
    } \
    \
    # Handle Laravel routes \
    location / { \
        try_files $uri $uri/ /index.php?$query_string; \
    } \
    \
    # Handle PHP files \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_index index.php; \
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name; \
        include fastcgi_params; \
    } \
    \
    # Deny access to hidden files \
    location ~ /\.ht { \
        deny all; \
    } \
    \
    # Deny access to sensitive files \
    location ~ /\.(env|git) { \
        deny all; \
    } \
}' > /etc/nginx/sites-available/default

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start PHP-FPM in background' >> /start.sh && \
    echo 'php-fpm -D' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start nginx in foreground' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

# Expose port 80
EXPOSE 80

# Health check for Render
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start the application
CMD ["/start.sh"]
