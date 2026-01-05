FROM debian:bookworm

RUN apt-get update -y && apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/setup-ssl.sh /tmp/setup-ssl.sh

RUN chmod +x /tmp/setup-ssl.sh

EXPOSE 443

CMD ["/tmp/setup-ssl.sh"]