# ---------- Stage 1: Build assets with Node ----------
    FROM node:22.14.0 AS node_builder

    WORKDIR /app
    
    # Copy only package files first for caching
    COPY package*.json ./
    
    # Install dependencies with pinned versions
    RUN npm ci
    
    # Copy the rest of the app
    COPY . .
    
    # Build assets (Vite + Tailwind)
    RUN npm run build
    
    
  # ---------- Stage 2: PHP + Apache ----------
    FROM php:8.1.25-apache

    # Install system dependencies + PostgreSQL headers
    RUN apt-get update && apt-get install -y \
        git unzip curl libpng-dev libonig-dev libxml2-dev zip libpq-dev \
        && docker-php-ext-install pdo_pgsql mbstring exif pcntl bcmath gd
    
    # Enable Apache Rewrite
    RUN a2enmod rewrite
    
    # Use Composer (pinned to 2.8.9 as you specified)
    COPY --from=composer:2.8.9 /usr/bin/composer /usr/bin/composer
    
    WORKDIR /var/www/html

    # Set DocumentRoot to /public
    ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
    RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf \
        && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
    
    # Copy app
    COPY . .
    COPY --from=node_builder /app/public/build ./public/build
    
    # Install PHP deps
    RUN composer install --no-dev --optimize-autoloader
    
    # Permissions
    RUN chown -R www-data:www-data /var/www/html \
        && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache
    
    EXPOSE 80
    CMD ["apache2-foreground"]
    

    