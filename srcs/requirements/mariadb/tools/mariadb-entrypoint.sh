#!/bin/sh
set -eu

ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
DB_PASSWORD="$(cat /run/secrets/db_password)"

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null
fi

cat > /tmp/mariadb-init.sql <<-SQL
	ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
	DELETE FROM mysql.user WHERE User='';
	DROP DATABASE IF EXISTS test;
	DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
	CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
	CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'wordpress.inception' IDENTIFIED BY '${DB_PASSWORD}';
	ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
	ALTER USER '${MYSQL_USER}'@'wordpress.inception' IDENTIFIED BY '${DB_PASSWORD}';
	GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
	GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'wordpress.inception';
	FLUSH PRIVILEGES;
SQL

chown mysql:mysql /tmp/mariadb-init.sql
chmod 600 /tmp/mariadb-init.sql

exec "$@" --init-file=/tmp/mariadb-init.sql
