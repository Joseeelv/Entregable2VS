FROM matomo:latest

# Información del mantenedor
LABEL maintainer="test@test.com"
LABEL description="Imagen personalizada de Matomo con extensiones PHP adicionales"

# Instalar extensiones PHP adicionales necesarias para Matomo
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    opcache \
    intl \
    mbstring \
    zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configurar opcache para mejor rendimiento
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Configurar límites de PHP
RUN { \
    echo 'upload_max_filesize=512M'; \
    echo 'post_max_size=512M'; \
    echo 'memory_limit=512M'; \
    echo 'max_execution_time=300'; \
    } > /usr/local/etc/php/conf.d/custom.ini

# Establecer permisos adecuados
RUN chown -R www-data:www-data /var/www/html

# Exponer puerto 80
EXPOSE 80

# Comando por defecto heredado de la imagen base
CMD ["apache2-foreground"]