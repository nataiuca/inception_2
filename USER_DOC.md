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

Before accessing the site, the domain must point to the machine running NGINX.

If the browser is opened inside the virtual machine, add this line to `/etc/hosts` if it is not already present:

```text
127.0.0.1 natferna.42.fr
```

If the browser is opened from the host machine and the project runs inside a bridged virtual machine, use the VM IP address instead:

```text
192.168.x.x natferna.42.fr
```

Replace `192.168.x.x` with the real VM IP address.

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

The regular WordPress user created by the stack is:

```text
natferna_user
```

Passwords are read from the local secret files described below.

## Credentials

Credentials are stored locally in the `secrets` directory.

Expected files:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

These files should contain one password each. Real passwords should not be committed to a public repository.

Usernames and non-sensitive configuration are stored in `srcs/.env`. If you need a local reminder during evaluation, create `secrets/credentials.txt` yourself and keep it out of Git. The tracked `secrets/credentials.example` file documents which local secret files are expected without storing real passwords.

If a password file is changed after WordPress and MariaDB have already been initialized, the existing database and WordPress accounts may still keep their previous passwords. To apply new initial secrets from a clean state, run `make fclean`, recreate the secret files if needed, and then start the project again with `make`.

## Check Service Status

List running containers:

```bash
make ps
```

Expected containers:

- `nginx`
- `wordpress`
- `mariadb`

Expected local project images:

- `nginx:inception`
- `wordpress:inception`
- `mariadb:inception`

Check logs:

```bash
make logs
```

Check HTTPS:

```bash
curl -k https://natferna.42.fr
curl -k -I https://natferna.42.fr
```

The `-k` option is needed because the project uses a self-signed TLS certificate.

Check the administration page:

```bash
curl -k -I https://natferna.42.fr/wp-admin/
```

Expected result when not logged in:

```text
HTTP/1.1 302 Found
Location: https://natferna.42.fr/wp-login.php
```

This means the HTTPS entrypoint, WordPress, and the login flow are working.

## Check Persistence

To verify that data is not lost when containers are removed:

1. Create or edit a WordPress post from the browser.
2. Run:

```bash
make down
make
```

3. Open `https://natferna.42.fr` again and check that the post still exists.

`make down` removes containers and the Docker network, but it does not remove the persistent MariaDB and WordPress data.

## Full Reset

Use this only when you want to remove all project data and start from an empty WordPress installation:

```bash
make fclean
make
```

`make fclean` removes containers, project images, Docker volumes, and the host data directories under `/home/natferna/data`.
