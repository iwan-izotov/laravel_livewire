#!/bin/bash

# Устанавливаем необходимые библиотеки для оптимизации изображений
apt-get update \
 && apt-get install -y jpegoptim optipng pngquant gifsicle libavif-bin \
 && snap install svgo

# Устанавливаем необходимые зависимости для imagic
apt-get update && apt-get install -y gcc make autoconf libc-dev pkg-config libmagickwand-dev libmagickcore-dev libwebp-dev

# Устанавливаем Imagick через PECL и подключаем PHP-расширение
# Это дефолтный варинт установки Imagick, но он не работает в PHP 8.3, как заработает, нужно использовать его
# pecl install imagick && docker-php-ext-enable imagick

# Устанавливаем Imagick из сырцов (так как установка через pecl в PHP 8.3 не работает) и подключаем PHP-расширение
apt-get install -y git && \
    git clone https://github.com/Imagick/imagick.git --depth 1 /tmp/imagick && \
    cd /tmp/imagick && \
    git fetch origin master && \
    git switch master && \
    cd /tmp/imagick && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    docker-php-ext-enable imagick
