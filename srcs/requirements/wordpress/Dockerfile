FROM debian:bookworm

RUN apt-get update -y && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-xmlrpc \
    php8.2-soap \
    php8.2-intl \
    php8.2-zip \
    mariadb-client \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
RUN mkdir -p /var/www/html /run/php
RUN cd /var/www/html && wp core download --allow-root
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 0.0.0.0:9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf && \
    sed -i 's/;clear_env = no/clear_env = no/' \
    /etc/php/8.2/fpm/pool.d/www.conf

COPY ./tools/setup-wordpress.sh /tmp/setup-wordpress.sh
RUN chmod +x /tmp/setup-wordpress.sh

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/tmp/setup-wordpress.sh"]