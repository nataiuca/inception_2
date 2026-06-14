# User Documentation

## Provided Services

This stack provides a WordPress website available through HTTPS at:

```text
https://natferna.42.fr
```

The services are:

- NGINX: public HTTPS entrypoint.
- WordPress: website and administration interface.
- MariaDB: database used by WordPress.

Only NGINX is reachable from outside the Docker network. WordPress and MariaDB communicate internally.

## Start and Stop the Project

Start the stack:

```bash
make
```

Stop the stack without removing containers:

```bash
make stop
```

Stop and remove containers and the project network:

```bash
make down
```

Restart the stack:

```bash
make restart
```

Show logs:

```bash
make logs
```

## Access the Website

Before accessing the site, the domain must point to the local machine. Add this line to `/etc/hosts` if it is not already present:

```text
127.0.0.1 natferna.42.fr
```

Website:

```text
https://natferna.42.fr
```

Administration panel:

```text
https://natferna.42.fr/wp-admin
```

The administrator username is:

```text
natferna_owner
```

## Credentials

Credentials are stored locally in the `secrets` directory.

Expected files:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

These files should contain one password each. Real passwords should not be committed to a public repository.

## Check Service Status

List running containers:

```bash
make ps
```

Expected containers:

- `nginx`
- `wordpress`
- `mariadb`

Check logs:

```bash
make logs
```

Check HTTPS:

```bash
curl -k https://natferna.42.fr
```

The `-k` option is needed because the project uses a self-signed TLS certificate.
