#!/bin/sh
set -eu

DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

mkdir -p /var/www/html /run/php
chown -R www-data:www-data /var/www/html /run/php

until mariadb-admin ping -h mariadb -u"${MYSQL_USER}" -p"${DB_PASSWORD}" >/dev/null 2>&1; do
	sleep 1
done

if [ ! -f /var/www/html/wp-config.php ]; then
	wp core download --allow-root --path=/var/www/html --force

	wp config create \
		--allow-root \
		--path=/var/www/html \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${DB_PASSWORD}" \
		--dbhost=mariadb:3306

	wp core install \
		--allow-root \
		--path=/var/www/html \
		--url="${WP_URL}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email

	wp user create \
		"${WP_USER}" \
		"${WP_USER_EMAIL}" \
		--allow-root \
		--path=/var/www/html \
		--user_pass="${WP_USER_PASSWORD}" \
		--role=author

	wp option update siteurl "${WP_URL}" --allow-root --path=/var/www/html
	wp option update home "${WP_URL}" --allow-root --path=/var/www/html
fi

chown -R www-data:www-data /var/www/html

exec "$@"
