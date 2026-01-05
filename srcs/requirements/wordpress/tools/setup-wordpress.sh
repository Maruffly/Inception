#!/bin/bash
set -e

RED='\033[31m'
CYAN='\033[36m'
BOLD='\033[1m'
BLUE='\033[34m'
GREEN='\033[32m'
BLINK='\033[5m'
RESET='\033[0m'
YELLOW='\033[33m'
MAGENTA='\033[35m'

echo -e "${CYAN}${BOLD}${BLINK}Loading WordPress secrets...${RESET}"

if [ -f /run/secrets/db_password ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
else
    echo -e "${RED}${BOLD}Db_password secret not found${RESET}"
    exit 1
fi

if [ -f /run/secrets/credentials ]; then
    WP_ADMIN_PASSWORD=$(head -n 1 /run/secrets/credentials)
    WP_USER_PASSWORD=$(tail -n 1 /run/secrets/credentials)
else
    echo -e "${RED}${BOLD}Credentials secret not found${RESET}"
    exit 1
fi

export WORDPRESS_DB_HOST=${DB_HOST:-mariadb}
export WORDPRESS_DB_NAME=${DB_NAME:-wordpress}
export WORDPRESS_DB_USER=${DB_USER:-wordpress}
export WORDPRESS_DB_PASSWORD=${DB_PASSWORD}

echo -e "${CYAN}Secrets loaded${RESET}"
echo -e "${CYAN}Database: ${WORDPRESS_DB_NAME}${RESET}"
echo -e "${CYAN}DB User: ${WORDPRESS_DB_USER}${RESET}"

echo -e "${YELLOW}${BLINK}Waiting for MariaDB..."
MAX_TRIES=30
COUNT=0

while [ $COUNT -lt $MAX_TRIES ]; do
    if mysql -h "${WORDPRESS_DB_HOST}" -u "${WORDPRESS_DB_USER}" "-p${WORDPRESS_DB_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}Database is ready!${RESET}"
        break
    fi
    
    COUNT=$((COUNT + 1))
    echo -e "${YELLOW}Attempt ${COUNT}/${MAX_TRIES}...${RESET}"
    sleep 2
done

if [ $COUNT -eq $MAX_TRIES ]; then
    echo -e "${RED}Failed to connect to MariaDB${RESET}"
    exit 1
fi

cd /var/www/html

if [ ! -f wp-config.php ]; then
    echo -e "${CYAN}${BOLD}Creating wp-config.php...${RESET}"
    
    wp config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="${WORDPRESS_DB_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --allow-root
    
    # Additional config
    wp config set WP_HOME "https://${DOMAIN_NAME}" --allow-root
    wp config set WP_SITEURL "https://${DOMAIN_NAME}" --allow-root
    wp config set FS_METHOD 'direct' --allow-root
    wp config set DISALLOW_FILE_EDIT true --raw --allow-root
    wp config set WP_DEBUG false --raw --allow-root

    if ! wp core is-installed --allow-root; then
            echo "${CYAN}${BLINK}Installing WordPress...${RESET}"
            wp core install \
            --url="https://${DOMAIN_NAME}" \
            --title="${WP_TITLE}" \
            --admin_user="${WP_ADMIN_USER}" \
            --admin_password="${WP_ADMIN_PASSWORD}" \
            --admin_email="${WP_ADMIN_EMAIL}" \
            --skip-email \
            --allow-root
    else
        echo "${GREEN}${BLINK}WordPress already installed${RESET}"
    fi

    # Additional user
    if [ -n "${WP_USER}" ] && [ -n "${WP_USER_EMAIL}" ]; then
        echo -e "${YELLOW}Creating user: ${WP_USER}${RESET}"
        wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
            --role=author \
            --user_pass="${WP_USER_PASSWORD}" \
            --allow-root 2>/dev/null || echo -e "${RED}User already exists${RESET}"
    fi
    
    echo -e "${GREEN}${BOLD}ordPress installed!${RESET}"
else
    echo -e "${YELLOW}WordPress already configured${RESET}"
fi

# Permissions
echo -e "${YELLOW}Setting permissions...${RESET}"
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo -e "${GREEN}${BOLD}${BLINK}Starting PHP-FPM 8.2...${RESET}"

# Launch PHP-FPM 8.2 in foreground
exec php-fpm8.2 -F