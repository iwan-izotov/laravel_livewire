FROM php:8.4-fpm

# Surpresses debconf complaints of trying to install apt packages interactively
# https://github.com/moby/moby/issues/4032#issuecomment-192327844
ARG DEBIAN_FRONTEND=noninteractiv

ARG PHP_FPM_UID
ARG PHP_FPM_GUID
ARG PHP_FPM_USER
ARG PHP_FPM_GROUP
RUN addgroup --gid ${PHP_FPM_GUID} --system ${PHP_FPM_GROUP} \
  && adduser --uid ${PHP_FPM_UID} --system --disabled-login --disabled-password --gid ${PHP_FPM_GUID} --home /home/${PHP_FPM_USER} ${PHP_FPM_USER}
RUN usermod -a -G sudo ${PHP_FPM_USER}

# Копируем общие скрипты
COPY ./shared/ /tmp/scripts/
RUN chmod +x -R /tmp/scripts/

# копирование php.ini
COPY ./php/shared_config/php.ini /usr/local/etc/php/php.ini

# Копируем общие скрипты для php-контейнеров
COPY ./php/shared_scripts/ /tmp/php_scripts/
RUN chmod +x -R /tmp/php_scripts/

# Установка TIMEZONE
ARG TIMEZONE
RUN /tmp/scripts/install_timezone.sh ${TIMEZONE}

RUN apt-get update -y && apt-get upgrade -y


# Устанавливаем полезные утилиты
RUN /tmp/scripts/install_software.sh

# Устанавливаем php extensions
RUN /tmp/php_scripts/install_extensions.sh

# Устанавливаем composer
RUN /tmp/php_scripts/install_composer.sh

# Устанавливаем mhsendmail
RUN /tmp/php_scripts/install_mhsendmail.sh

# Устанавливаем nodejs и npm
RUN /tmp/php_scripts/install_nodejs_npm.sh

# Устанавливаем библиотеки для медиа
RUN /tmp/php_scripts/install_media_software.sh

ARG XDEBUG_REMOTE_HOST
ARG XDEBUG_REMOTE_PORT
ARG MAILHOG_IP
RUN /tmp/php_scripts/setting_variables.sh ${XDEBUG_REMOTE_HOST} ${XDEBUG_REMOTE_PORT} ${MAILHOG_IP}

# проставляет php-fpm запуск от пользователя PHP_FPM_USER и группы PHP_FPM_GROUP
RUN /tmp/php_scripts/set_fpm_user_and_group.sh ${PHP_FPM_USER} ${PHP_FPM_GROUP}

# Установка nopassword пользователю
RUN /tmp/php_scripts/set_sudoers.sh ${PHP_FPM_USER}

# Очистка
RUN /tmp/php_scripts/cleanup.sh

USER ${PHP_FPM_USER}

# Устанавливаем рабочую дерикторию
WORKDIR /var/www/shop

# Устанавливаем подстветку bash
COPY ./shared/.bashrc /home/${PHP_FPM_USER}/.bashrc

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
