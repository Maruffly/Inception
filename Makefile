NAME = inception

all: up

init:
	mkdir -p /home/jmaruffy/data/wordpress
	mkdir -p /home/jmaruffy/data/mariadb

build:
	sudo docker-compose -f srcs/docker-compose.yml build

up: init
	sudo docker-compose -f srcs/docker-compose.yml up -d

down:
	sudo docker-compose -f srcs/docker-compose.yml down

clean: down
	sudo docker system prune -af
	sudo docker volume prune -f

fclean: clean
	sudo rm -rf /home/jmaruffy/data

re: fclean all
