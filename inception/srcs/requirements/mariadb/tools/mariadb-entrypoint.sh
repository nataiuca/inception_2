#!/bin/sh
set -eu

ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
DB_PASSWORD="$(cat /run/secrets/db_password)"

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null

	mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/tmp/mysqld.sock &
	pid="$!"

	until mariadb-admin --socket=/tmp/mysqld.sock ping >/dev/null 2>&1; do
		sleep 1
	done

	mariadb --socket=/tmp/mysqld.sock <<-SQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'wordpress.inception' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'wordpress.inception';
		FLUSH PRIVILEGES;
	SQL

	mariadb-admin --socket=/tmp/mysqld.sock -uroot -p"${ROOT_PASSWORD}" shutdown
	wait "$pid"
else
	mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/tmp/mysqld.sock &
	pid="$!"

	until mariadb-admin --socket=/tmp/mysqld.sock ping >/dev/null 2>&1; do
		sleep 1
	done

	mariadb --socket=/tmp/mysqld.sock -uroot -p"${ROOT_PASSWORD}" <<-SQL
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'wordpress.inception' IDENTIFIED BY '${DB_PASSWORD}';
		ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		ALTER USER '${MYSQL_USER}'@'wordpress.inception' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'wordpress.inception';
		FLUSH PRIVILEGES;
	SQL

	mariadb-admin --socket=/tmp/mysqld.sock -uroot -p"${ROOT_PASSWORD}" shutdown
	wait "$pid"
fi

exec "$@"
