#!/bin/bash

#stop script if fail
set -e 

# TESTS:
# sudo docker exec -it mariadb mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
# SELECT 'Root connection: OK' AS Status;
# sudo docker-compose exec mariadb mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e
# SELECT 'User connection: OK' AS Status;

RED='\033[31m'
CYAN='\033[36m'
BOLD='\033[1m'
BLUE='\033[34m'
GREEN='\033[32m'
BLINK='\033[5m'
RESET='\033[0m'
YELLOW='\033[33m'
MAGENTA='\033[35m'

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

echo -e "${CYAN}${BOLD}${BLINK}Loading secrets... ${RESET}"

#load mySQL in the background
mysqld_safe --datadir=/var/lib/mysql &
sleep 5

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo -e "${YELLOW}First-time setup: creating DB and users... ${RESET}"
    mysql -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL
else
    echo -e "${YELLOW}Database already exists. Checking root access... ${RESET}"
    if ! mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${MAGENTA} ${BLINK} Resetting root password... ${RESET}"
        mysql -u root <<-EOSQL
            ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
EOSQL
    else
        echo -e "${GREEN}Root password is already valid. ${RESET}"
    fi
fi

echo -e "${GREEN}${BOLD}${BLINK}MariaDB ready and running.${RESET}"
wait
