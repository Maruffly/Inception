#!/bin/bash

RED='\033[31m'
CYAN='\033[36m'
BOLD='\033[1m'
BLUE='\033[34m'
GREEN='\033[32m'
BLINK='\033[5m'
RESET='\033[0m'
YELLOW='\033[33m'
MAGENTA='\033[35m'

SSL_DIR="/etc/ssl/private"

mkdir -p ${SSL_DIR}

if [ ! -f "${SSL_DIR}/cert.pem" ] || [ ! -f "${SSL_DIR}/key.pem" ]; then
    echo -e "${CYAN}${BOLD}${BLINK}Generating auto-signed certificate${RESET}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${SSL_DIR}/key.pem" \
        -out "${SSL_DIR}/cert.pem" \
        -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=jmaruffy/CN=jmaruffy.42.fr"
else
    echo -e "${YELLOW}Certificate already valid${RESET}"
fi

echo -e "${GREEN}${BOLD}${BLINK}Launch NGINX...${RESET}"
exec nginx -g "daemon off;"