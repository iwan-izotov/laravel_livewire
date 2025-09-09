include ./docker/env/main.env
-include ./docker/env/.env

## Объединяет все env файлы в одну команду
MAIN_ENV = ./docker/env/main.env
LOCAL_ENV = ./docker/env/.env
ENV_COMMAND = --env-file=$(MAIN_ENV) --env-file=$(LOCAL_ENV)

## Объединяет все docker-compose файлы в одну команду
LOCAL_FILE_COMMAND=
ifdef DOCKER_COMPOSE_EXTENDED_FILES
	LOCAL_FILE_COMMAND = -f $(subst ;, -f , $(DOCKER_COMPOSE_EXTENDED_FILES))
endif

FILE_COMMAND = -f ./docker/docker-compose/docker-compose.yml $(LOCAL_FILE_COMMAND)

## Устанавливаем рабочую директорию
PD_COMMAND = --project-directory ./

PRE_ENV_COMMAND = COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1

DEFAULT_GOAL := help

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

./docker/env/.env:
	cp ./docker/env/.env.example ./docker/env/.env

.PHONY:
create-docker-env: ./docker/env/.env ##Проверяет, если .env файл для докер-сборки не существует, то создаёт его

.PHONY: docker-prune
docker-prune: ## Удаляет неиспользуемые ресурсы докера с помощью 'docker system prune -a -f --volumes'
	docker system prune -a -f --volumes

.PHONY: up
up: create-docker-env ## Запускает все Docker-контейнеры в фоновом режиме
	$(PRE_ENV_COMMAND) docker compose $(FILE_COMMAND) $(ENV_COMMAND) -p $(PROJECT_NAME) $(PD_COMMAND) up -d --build

.PHONY: down
down: create-docker-env ## Останавливает контейнеры и удаляет их
	$(PRE_ENV_COMMAND) docker compose $(FILE_COMMAND) $(ENV_COMMAND) -p $(PROJECT_NAME) $(PD_COMMAND) down --remove-orphans

.PHONY: docker-up
docker-up: create-docker-env ## Запускает все Docker-контейнеры в фоновом режиме
	$(PRE_ENV_COMMAND) docker-compose $(FILE_COMMAND) $(ENV_COMMAND) -p $(PROJECT_NAME) $(PD_COMMAND) up -d --build

.PHONY: docker-down
docker-down: create-docker-env ## Останавливает контейнеры и удаляет их
	$(PRE_ENV_COMMAND) docker-compose $(FILE_COMMAND) $(ENV_COMMAND) -p $(PROJECT_NAME) $(PD_COMMAND) down --remove-orphans

.PHONY: console
console: ## Запускает bash на контейнере php-fpm (для запуска консольных команд)
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && bash'

.PHONY: npm-build
npm-build: ## Запускает команду npm run build
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && npm run build'

.PHONY: npm-dev
npm-dev: ## Запускает команду npm run dev
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && npm run dev'

.PHONY: install-composer
install-composer: ## Устанавливает библиотеки компосера
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && composer install'

.PHONY: key-generate
key-generate: ## Запускает установку миграций
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan key:generate --ansi'

.PHONY: install-npm
install-npm: ## Устанавливает библиотеки npm
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && npm install'

.PHONY: install-migrate
install-migrate: ## Запускает установку миграций
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && echo -ne "yes\n" | php artisan migrate'

.PHONY: prepare-dirs
prepare-dirs: ## Проставляет права 777 для папок
	chmod -R 777 storage
	chmod -R 777 bootstrap

.PHONY: install-all ## Запускает установку всего окружения: установка библиотек компосера, npm, накатка миграций и др..
install-all: prepare-dirs install-composer key-generate storage-link install-npm install-migrate npm-build ## Устанавливает всё окружение

.PHONY: dos2unix
dos2unix: ## Конвертируют все файлы в директории docker: убирает BOM символы, меняет CRLF на LF
	bash -c 'cd ./docker && find . -type f -print0 | xargs -0 dos2unix && cd ../'

.PHONY: clear-memcached
clear-memcached: ## Очищает весь кеш в memcached
	docker exec -it $(PROJECT_NAME)_memcached bash -c 'echo flush_all > /dev/tcp/localhost/11211'

.PHONY: clear-cache
clear-cache: ## Очищает весь кеш в Laravel (удаляет все элементы из кеша, независимо от используемого драйвера кеша)
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan cache:clear'

.PHONY: clear-cache-route
clear-cache-route: ## Очищает кэш маршрутов
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan route:clear'

.PHONY: clear-cache-config
clear-cache-config: ## Очищает кэш конфигурации
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan config:clear'

.PHONY: clear-cache-event
clear-cache-event: ## Очищает кэш событий
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan event:clear'

.PHONY: clear-cache-view
clear-cache-view: ## Очищает кэш скомпилированных представлений
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan view:clear'

.PHONY: clear-all-caches
clear-all-caches: clear-cache clear-cache-route clear-cache-config clear-cache-view clear-cache-event ## Очищает все закешированные данные, кэш маршрутов, кэш конфигурации, кэш скомпилированных представлений, кэш событий

.PHONY: install-stage
install-stage: ## Устанавливает Stage сервер
	docker exec -it $(PROJECT_NAME)_ansible bash -c 'cd /var/ansible/src && ansible-playbook -i hosts stage.yml'

.PHONY: install-ci
install-ci: ## Устанавливает CI сервер
	docker exec -it $(PROJECT_NAME)_ansible bash -c 'cd /var/ansible/src && ansible-playbook -i hosts ci.yml'

.PHONY: clone-git-stage
clone-git-stage: ## Затягивает изменения из git на Stage сервер
	docker exec -it $(PROJECT_NAME)_ansible bash -c 'cd /var/ansible/src && ansible-playbook -i hosts stage_clone_git.yml'

.PHONY: schedule-list
schedule-list: ## Выводит расписание планировщика задач
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan schedule:list'

.PHONY: run-test
run-test: ## Запускает все тесты Unit и Feature тесты
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan test'

.PHONY: run-dusk-test
run-dusk-test: ## Запускает браузерные тесты (dusk тесты)
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan dusk'

.PHONY: phpstan
phpstan: ## Запускает phpstan
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && ./vendor/bin/phpstan analyse'

.PHONY: pint
pint: ## Запускает pint
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && ./vendor/bin/pint'

.PHONY: swagger
swagger: ## Запускает генерацию документации swagger
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan l5-swagger:generate'

.PHONY: storage-link
storage-link: ## Создаёт символическую ссылку с public/storageна storage/app/public
	docker exec -it $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan storage:link'


.PHONY: install-composer-ci
install-composer-ci: ## Устанавливает библиотеки компосера (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && composer install'

.PHONY: composer-audit-ci
composer-audit-ci: ## Проверяет библиотеки на уязвимости (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && COMPOSER_AUDIT_ABANDONED=ignore composer audit'

.PHONY: phpstan-ci
phpstan-ci: ## Запускает phpstan (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && ./vendor/bin/phpstan analyse'

.PHONY: pint-ci
pint-ci: ## Запускает pint (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && ./vendor/bin/pint --test'

.PHONY: migrate-ci
migrate-ci: ## Запускает миграции (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan migrate --force'

.PHONY: clear-cache-ci
clear-cache-ci: ## Запускает очистку всех кешей (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop/ && php artisan cache:clear && php artisan route:clear && php artisan config:clear && php artisan view:clear'

.PHONY: install-npm-ci
install-npm-ci: ## Запускает установку зависимостей npm (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop && npm install'

.PHONY: build-assets-ci
build-assets-ci: ## Запускает билд ресурсов (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop && npm run build'

.PHONY: tests-ci
tests-ci: ## Запускает тесты (используется для CI)
	docker exec -i $(PROJECT_NAME)_php_fpm bash -c 'cd /var/www/shop && php artisan test'

.PHONY: clear-mailhog-ci
clear-mailhog-ci: ## Очищает mailhog (используется для CI)
	curl -X DELETE http://mailhog.$(DOMEN_2_LEVEL).local/api/v1/messages
