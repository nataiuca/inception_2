*This project has been created as part of the 42 curriculum by natferna.*

# Inception

## Description

Inception is a system administration project based on Docker. The goal is to build a small infrastructure composed of independent services running in dedicated containers.

The mandatory stack contains:

- NGINX as the only public entrypoint, exposed only on port 443 with TLSv1.2/TLSv1.3.
- WordPress with PHP-FPM, without NGINX.
- MariaDB, without NGINX.
- A private Docker network shared by the services.
- Two Docker named volumes for persistent data.
- Custom images built from `debian:bookworm`, without ready-made NGINX, WordPress, or MariaDB images.
- Secrets stored outside `.env` and Dockerfiles.

The domain used by this project is:

```text
natferna.42.fr
```

For virtual machine setup, host access, SSH, networking checks, and deeper implementation notes, see [`DEV_DOC.md`](DEV_DOC.md).

## Instructions

Before starting the project, make sure Docker and Docker Compose are installed on the virtual machine.

Add the local domain to `/etc/hosts`:

```bash
sudo sh -c 'echo "127.0.0.1 natferna.42.fr" >> /etc/hosts'
```

Create the data directories:

```bash
sudo mkdir -p /home/natferna/data/mariadb
sudo mkdir -p /home/natferna/data/wordpress
sudo chown -R "$USER:$USER" /home/natferna/data
```

The persistent data path is configured in `srcs/.env`:

```env
DATA_PATH=/home/natferna/data
WP_URL=https://natferna.42.fr
```

The `.env` file must only contain non-sensitive configuration. Passwords are read from Docker secrets.

Create the secret files in the `secrets` directory before launching the stack:

```bash
printf 'your-root-password\n' > secrets/db_root_password.txt
printf 'your-database-password\n' > secrets/db_password.txt
printf 'your-wordpress-owner-password\n' > secrets/wp_admin_password.txt
printf 'your-wordpress-user-password\n' > secrets/wp_user_password.txt
```

Start the project:

```bash
make
```

Check running containers:

```bash
make ps
```

Stop and remove the project containers and network:

```bash
make down
```

Stop containers without removing them:

```bash
make stop
```

Remove containers, network, and project images while preserving persistent data:

```bash
make clean
```

Remove containers, volumes, images, and host data for a full reset:

```bash
make fclean
```

## Project Description

### Docker and Project Sources

Each service has its own Dockerfile and is built from `debian:bookworm`, without using ready-made service images. Docker Compose builds the images and starts the containers.

The source tree is organized under `srcs/requirements`, with one directory per service:

- `mariadb`: database installation, configuration, and initialization script.
- `wordpress`: PHP-FPM, WordPress installation, and WordPress user creation.
- `nginx`: TLS certificate generation and HTTPS reverse proxy configuration.

### Virtual Machines vs Docker

A virtual machine runs a complete guest operating system with its own kernel. Docker containers share the host kernel and isolate processes using Linux features such as namespaces and cgroups. Containers are lighter, faster to start, and better suited for splitting services into small units.

### Secrets vs Environment Variables

Environment variables are useful for non-sensitive configuration, such as domain names, paths, database names, URLs, and usernames. Secrets are used for confidential values because they are mounted as files at runtime and are not written directly into Dockerfiles or `.env`.

### Docker Network vs Host Network

The project uses a custom Docker bridge network. Containers can communicate by service name, for example WordPress connects to `mariadb`. The host network is not used because it would reduce isolation and is forbidden by the subject.

### Docker Volumes vs Bind Mounts

Docker volumes persist data after containers are removed. This project declares two Docker named volumes:

- `mariadb_data`
- `wordpress_data`

The services do not mount host paths directly with a service-level bind mount such as `/home/natferna/data:/var/lib/mysql`. Instead, the services mount the named volumes declared in the top-level `volumes:` section of `srcs/docker-compose.yml`.

Those named volumes use the local Docker driver with `driver_opts` so their physical storage is placed under `DATA_PATH`, configured as `/home/natferna/data`, as required by the subject:

```text
/home/natferna/data/mariadb
/home/natferna/data/wordpress
```

During defense, the important distinction is that Docker still manages and lists them as named volumes:

```bash
docker volume ls
docker volume inspect mariadb_data
docker volume inspect wordpress_data
```

`make clean` preserves this persistent data. `make fclean` removes the Docker volumes and deletes the host data directories.

## Evaluation Checklist

Useful checks after `make`:

```bash
docker ps
docker network inspect inception
docker volume inspect mariadb_data
docker volume inspect wordpress_data
curl -k -I https://natferna.42.fr
docker exec wordpress wp db check --allow-root --path=/var/www/html
docker exec wordpress wp user list --allow-root --path=/var/www/html
```

Expected behavior:

- Only `nginx` exposes `0.0.0.0:443->443/tcp`.
- `wordpress` listens internally on port `9000`.
- `mariadb` listens internally on port `3306`.
- `https://natferna.42.fr` responds through the self-signed TLS certificate.
- `/wp-admin/` redirects unauthenticated users to the WordPress login page.
- WordPress users `natferna_owner` and `natferna_user` exist.
- Data survives `make down` followed by `make`.

## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- Debian documentation: https://www.debian.org/doc/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- NGINX documentation: https://nginx.org/en/docs/
- WordPress documentation: https://wordpress.org/documentation/
- WP-CLI documentation: https://wp-cli.org/
