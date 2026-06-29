COMPOSE = docker compose --env-file srcs/.env -f srcs/docker-compose.yml

include srcs/.env
DATA_DIR = $(DATA_PATH)

.PHONY: all build up stop down restart logs ps clean fclean re

all: up

build:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) build

up:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) up -d --build

stop:
	$(COMPOSE) stop

down:
	$(COMPOSE) down

restart: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --rmi all

fclean:
	-$(COMPOSE) down --rmi all -v
	sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	-docker system prune -af

re: fclean all
