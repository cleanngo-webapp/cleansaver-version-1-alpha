# Stage 1 - Build Frontend (Vite)
FROM node:18 AS frontend
WORKDIR /app

# Install pnpm (since your project uses pnpm)
RUN npm install -g pnpm

# Copy package files
COPY package*.json pnpm-lock.yaml ./

# Install dependencies using pnpm
RUN pnpm install

# Copy source code (only what's needed for frontend build)
COPY resources/ ./resources/
COPY tailwind.config.js vite.config.js ./
COPY public/ ./public/

# Build frontend assets
RUN pnpm run build

# Stage 2 - Backend (Laravel + PHP + Composer)
FROM php:8.1-fpm AS backend

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    libpq-dev \
    libonig-dev \
    libzip-dev \
    zip \
    nginx \
    supervisor \
    && docker-php-ext-install pdo pdo_pgsql mbstring zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy composer files first for better caching
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy application code (excluding what's in .dockerignore)
COPY . .

# Copy built frontend from Stage 1 (correct path for Vite)
COPY --from=frontend /app/public/build ./public/build

# Create .env file from environment variables if it doesn't exist
RUN if [ ! -f .env ]; then \
        echo "APP_NAME=Laravel" > .env && \
        echo "APP_ENV=production" >> .env && \
        echo "APP_KEY=" >> .env && \
        echo "APP_DEBUG=false" >> .env && \
        echo "APP_URL=http://localhost" >> .env && \
        echo "DB_CONNECTION=pgsql" >> .env && \
        echo "DB_HOST=db" >> .env && \
        echo "DB_PORT=5432" >> .env && \
        echo "DB_DATABASE=cleanngo" >> .env && \
        echo "DB_USERNAME=postgres" >> .env && \
        echo "DB_PASSWORD=password" >> .env && \
        echo "LOG_CHANNEL=stack" >> .env && \
        echo "LOG_LEVEL=error" >> .env && \
        echo "CACHE_DRIVER=file" >> .env && \
        echo "SESSION_DRIVER=file" >> .env && \
        echo "QUEUE_CONNECTION=sync" >> .env; \
    fi

# Set proper permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Generate application key if not set and run Laravel setup
RUN php artisan key:generate --no-interaction || echo "Key generation failed, continuing..." && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Create nginx configuration
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /var/www/public; \
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
}' > /etc/nginx/sites-available/default

# Create supervisor configuration
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=root' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:php-fpm]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=php-fpm' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile=/var/log/php-fpm.err.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile=/var/log/php-fpm.out.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:nginx]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=nginx -g "daemon off;"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile=/var/log/nginx.err.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile=/var/log/nginx.out.log' >> /etc/supervisor/conf.d/supervisord.conf

# Expose port
EXPOSE 80

# Start supervisor to run both PHP-FPM and Nginx
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
