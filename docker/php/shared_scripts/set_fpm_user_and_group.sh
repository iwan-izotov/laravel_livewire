#!/bin/bash

PHP_FPM_USER=$1
PHP_FPM_GROUP=$2

sed -i "s/.*user = www-data.*/user = $PHP_FPM_USER/g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/.*group = www-data.*/group = $PHP_FPM_GROUP/g" /usr/local/etc/php-fpm.d/www.conf
