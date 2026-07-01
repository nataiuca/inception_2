#!/bin/sh
set -eu

ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
DB_PASSWORD="$(cat /run/secrets/db_password)"

sql_string() {
	printf "%s" "$1" | sed "s/'/''/g"
}

sql_identifier() {
	printf "%s" "$1" | sed 's/`/``/g'
}

ROOT_PASSWORD_SQL="$(sql_string "$ROOT_PASSWORD")"
DB_PASSWORD_SQL="$(sql_string "$DB_PASSWORD")"
MYSQL_USER_SQL="$(sql_string "$MYSQL_USER")"
MYSQL_DATABASE_SQL="$(sql_identifier "$MYSQL_DATABASE")"

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null
fi

cat > /tmp/mariadb-init.sql <<-SQL
	ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD_SQL}';
	DELETE FROM mysql.user WHERE User='';
	DROP DATABASE IF EXISTS test;
	DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE_SQL}\`;
	CREATE USER IF NOT EXISTS '${MYSQL_USER_SQL}'@'%' IDENTIFIED BY '${DB_PASSWORD_SQL}';
	CREATE USER IF NOT EXISTS '${MYSQL_USER_SQL}'@'wordpress.inception' IDENTIFIED BY '${DB_PASSWORD_SQL}';
	ALTER USER '${MYSQL_USER_SQL}'@'%' IDENTIFIED BY '${DB_PASSWORD_SQL}';
	ALTER USER '${MYSQL_USER_SQL}'@'wordpress.inception' IDENTIFIED BY '${DB_PASSWORD_SQL}';
	GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE_SQL}\`.* TO '${MYSQL_USER_SQL}'@'%';
	GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE_SQL}\`.* TO '${MYSQL_USER_SQL}'@'wordpress.inception';
	FLUSH PRIVILEGES;
SQL

chown mysql:mysql /tmp/mariadb-init.sql
chmod 600 /tmp/mariadb-init.sql

exec "$@" --init-file=/tmp/mariadb-init.sql
