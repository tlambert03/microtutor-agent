FROM php:8.3-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libonig-dev \
    zlib1g-dev \
    libpq-dev \
    libsodium-dev \
    libpspell-dev \
    libcurl4-openssl-dev \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# Configure LDAP (auto-detect architecture)
RUN docker-php-ext-configure ldap

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo_mysql \
        opcache \
        intl \
        soap \
        zip \
        mbstring \
        exif \
        ldap \
        xsl \
        sodium \
        pspell \
        curl \
        ftp \
        gettext \
        pcntl \
        sockets \
        shmop \
        sysvmsg \
        sysvsem \
        sysvshm

# Enable Apache modules
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Set permissions
RUN chown -R www-data:www-data /var/www/html
