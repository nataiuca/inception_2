FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		php8.2-fpm \
		php8.2-mysql \
		php8.2-curl \
		php8.2-gd \
		php8.2-intl \
		php8.2-mbstring \
		php8.2-xml \
		php8.2-zip \
		mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
	&& chmod +x /usr/local/bin/wp

COPY tools/wordpress-entrypoint.sh /usr/local/bin/wordpress-entrypoint.sh

RUN chmod +x /usr/local/bin/wordpress-entrypoint.sh \
	&& mkdir -p /run/php \
	&& sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf \
	&& sed -i 's|;clear_env = no|clear_env = no|' /etc/php/8.2/fpm/pool.d/www.conf

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["wordpress-entrypoint.sh"]
CMD ["php-fpm8.2", "-F"]
