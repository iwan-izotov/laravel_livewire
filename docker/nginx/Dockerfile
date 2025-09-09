FROM nginx

ARG DEBIAN_FRONTEND=noninteractiv

# Копируем общие скрипты
COPY ./shared/ /tmp/scripts/
RUN chmod +x -R /tmp/scripts/

# Устанавливаем полезные утилиты
RUN /tmp/scripts/install_software.sh

# Устанавливаем подстветку bash
COPY ./shared/.bashrc /root/.bashrc