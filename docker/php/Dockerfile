FROM php:8.2-cli-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        libzip-dev unzip libpng-dev libonig-dev libxml2-dev libcurl4-openssl-dev libicu-dev \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql mbstring zip gd bcmath exif pcntl intl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
