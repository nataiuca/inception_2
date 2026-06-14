# Developer Documentation

## Environment Setup

This project must run inside a virtual machine with Docker and Docker Compose installed.

Required host preparation:

```bash
sudo mkdir -p /home/natferna/data/mariadb
sudo mkdir -p /home/natferna/data/wordpress
sudo chown -R "$USER:$USER" /home/natferna/data
```

Add the domain to `/etc/hosts`:

```bash
sudo sh -c 'echo "127.0.0.1 natferna.42.fr" >> /etc/hosts'
```

The data directory is also declared in `srcs/.env`:

```env
DATA_PATH=/home/natferna/data
WP_URL=https://natferna.42.fr
```

`DATA_PATH` must match the host directories created above because Docker Compose uses it to configure the bind-backed named volumes.

## Virtual Machine and Host Access

The project is intended to run inside a Debian virtual machine. The campus Linux host is used for editing files and opening the WordPress site in Chrome.

The VM IP address depends on the current network. The examples below use `192.168.x.x`; replace it with the real IP shown by `ip a` inside the VM.

### Virtual Machine Creation

Recommended VirtualBox setup:

- Name: `inception`
- Operating system: Debian 64-bit
- RAM: at least 4096 MB
- CPUs: at least 2
- Disk: dynamically allocated VDI
- Network adapter: Bridged Adapter

The Bridged Adapter mode gives the VM an IP address on the same network as the Linux host. This makes it possible to access NGINX from the host browser.

During Debian installation, create the user with the 42 login:

```text
natferna
```

Install the SSH server during installation, or install it afterwards:

```bash
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

### Docker Installation inside the VM

Install Docker, Docker Compose, and build tools:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose build-essential
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Log out and log back in, or reboot the VM, so the Docker group change applies.

Check the installation:

```bash
docker --version
docker compose version
groups
```

### Basic VM Management

Useful commands inside the Debian VM:

| Task | Command |
| --- | --- |
| Reboot the VM | `sudo reboot` |
| Shut down the VM | `sudo poweroff` |
| Get the VM IP address | `ip a` |
| Switch to root | `su -` |
| Return to the project user | `su - natferna` |
| Disable graphical mode | `sudo systemctl set-default multi-user.target` |

### Optional Shared Folder

A shared folder can be used to edit files from the Linux host while running Docker inside the VM. In VirtualBox, configure a shared folder with a mount point such as:

```text
/home/natferna/inception
```

If manual mounting is needed inside the VM:

```bash
sudo mkdir -p /home/natferna/inception
sudo mount -t vboxsf -o uid=$(id -u),gid=$(id -g) inception /home/natferna/inception
sudo usermod -aG vboxsf "$USER"
```

Guest Additions may be required for shared folders:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
sudo mkdir -p /mnt/cdrom
sudo mount /dev/cdrom /mnt/cdrom
sudo /mnt/cdrom/VBoxLinuxAdditions.run
sudo reboot
```

After reboot, check that VirtualBox modules are loaded:

```bash
lsmod | grep vbox
```

### Finding the VM IP Address

Inside the VM, run:

```bash
ip a
```

Look for the IPv4 address on the main network interface, for example:

```text
192.168.x.x
```

This is the address used by the Linux host to reach the VM.

From the Linux host, verify that the VM answers:

```bash
ping 192.168.x.x
```

### SSH Access from the Linux Host

From the Linux host:

```bash
ssh natferna@192.168.x.x
```

Replace `192.168.x.x` with the current VM IP address.

SSH is useful for:

- launching the project inside the VM
- checking Docker state
- opening tunnels if direct access is not available
- debugging logs and network issues

### Domain Resolution

Inside the VM, the project domain should resolve to localhost because NGINX runs inside the VM:

```bash
sudo nano /etc/hosts
```

Add:

```text
127.0.0.1 natferna.42.fr
```

From the Linux host, if the VM uses Bridged Adapter and exposes port 443 directly, the domain should resolve to the VM IP address.

If `sudo` is available on the Linux host, edit:

```bash
sudo nano /etc/hosts
```

Add:

```text
192.168.x.x natferna.42.fr
```

Do not keep another active line for the same domain, such as:

```text
127.0.0.1 natferna.42.fr
```

If both lines exist, the host may resolve the domain to the wrong address.

Check the result:

```bash
ping natferna.42.fr
```

Expected result:

```text
natferna.42.fr (192.168.x.x)
```

### Checking Port 443 from the Linux Host

From the Linux host:

```bash
curl -k https://192.168.x.x
curl -k https://natferna.42.fr
```

If the IP works but the domain fails, the problem is usually the host `/etc/hosts` file.

### Accessing the Website from Chrome

After the containers are running inside the VM:

```bash
make
docker ps
```

Expected public port:

```text
0.0.0.0:443->443/tcp
```

Open Chrome on the Linux host at:

```text
https://natferna.42.fr
```

Chrome will show a privacy warning because the project uses a self-signed TLS certificate. This is expected for Inception. Continue to the site manually.

The WordPress admin panel is available at:

```text
https://natferna.42.fr/wp-admin
```

### Optional SSH Tunnel

If direct access to the VM IP is not possible, forward host port 443 to the VM:

```bash
ssh -L 443:localhost:443 natferna@192.168.x.x
```

With this tunnel active, the Linux host `/etc/hosts` file should use:

```text
127.0.0.1 natferna.42.fr
```

Without this tunnel, the Linux host should use the VM IP address instead.

### Chrome SOCKS Alternative without sudo

If `sudo` is not available on the Linux host and `/etc/hosts` cannot be edited, use an SSH SOCKS tunnel:

```bash
ssh -D 8080 natferna@192.168.x.x
```

Keep that terminal open, then launch Chrome with the SOCKS proxy:

```bash
google-chrome \
  --proxy-server="socks5://127.0.0.1:8080" \
  --host-resolver-rules="MAP * ~NOTFOUND, EXCLUDE localhost"
```

If the binary is named `chromium`, use:

```bash
chromium \
  --proxy-server="socks5://127.0.0.1:8080" \
  --host-resolver-rules="MAP * ~NOTFOUND, EXCLUDE localhost"
```

When using the SOCKS method, the VM must resolve the project domain locally:

```text
127.0.0.1 natferna.42.fr
```

in the VM file:

```text
/etc/hosts
```

If Chrome shows a proxy connection error, the SSH SOCKS command is probably not running or Chrome is pointing to the wrong local port.

## Configuration Files

Main files:

- `Makefile`: project commands.
- `srcs/docker-compose.yml`: service, network, volume, and secret definitions.
- `srcs/.env`: non-sensitive configuration.
- `secrets/*.txt`: confidential values.

Service files:

- `srcs/requirements/mariadb/Dockerfile`
- `srcs/requirements/wordpress/Dockerfile`
- `srcs/requirements/nginx/Dockerfile`

## Secrets

Create the secrets before launching the stack:

```bash
printf 'your-root-password\n' > secrets/db_root_password.txt
printf 'your-database-password\n' > secrets/db_password.txt
printf 'your-wordpress-owner-password\n' > secrets/wp_admin_password.txt
printf 'your-wordpress-user-password\n' > secrets/wp_user_password.txt
```

The Dockerfiles and `.env` do not contain passwords. Containers read secrets from `/run/secrets`.

## Build and Launch

Build images and launch containers:

```bash
make
```

Build only:

```bash
make build
```

Stop containers without removing them:

```bash
make stop
```

Stop and remove containers and the Docker Compose network:

```bash
make down
```

Rebuild from scratch:

```bash
make re
```

## Container and Volume Management

List containers:

```bash
make ps
```

View logs:

```bash
make logs
```

Remove containers, the Docker Compose network, and project images while preserving persistent data:

```bash
make clean
```

Remove containers, Docker volumes, images, and host data:

```bash
make fclean
```

## Data Persistence

MariaDB data is stored in:

```text
/home/natferna/data/mariadb
```

WordPress files are stored in:

```text
/home/natferna/data/wordpress
```

The containers can be removed and recreated while keeping the data, as long as these directories and their Docker volumes are not deleted.

Command behavior:

- `make down` removes containers and the project network. Persistent data remains.
- `make clean` also removes project images. Persistent data remains.
- `make fclean` removes project volumes and deletes `/home/natferna/data/mariadb` and `/home/natferna/data/wordpress`.

If Docker volumes were created with an incorrect host path, run `make fclean` and then `make` after confirming `DATA_PATH` and the host directories are correct.

## Core Docker Compose Commands

The Makefile wraps Docker Compose, but these commands are useful for understanding what happens underneath:

| Command | Purpose |
| --- | --- |
| `docker compose build` | Builds the images defined in `srcs/docker-compose.yml`. |
| `docker compose up -d` | Creates and starts the stack in detached mode. |
| `docker compose stop` | Stops containers without removing them. |
| `docker compose down` | Removes containers and the project network. |
| `docker compose ps` | Lists containers managed by Compose. |
| `docker compose down -v` | Removes containers, network, and project volumes. Used only by `make fclean`. |
| `docker system prune -af` | Removes unused Docker objects and build cache. Used by `make fclean`. |

If images are not rebuilt, changes in Dockerfiles or entrypoint scripts may not appear in running containers. Use `make clean && make` or `make re` after infrastructure changes.

## Container Theory

### Build Time vs Runtime

Docker images should remain stateless. Build time prepares infrastructure:

- base Debian system
- required packages
- static service configuration
- entrypoint scripts

Runtime manages state:

- MariaDB database initialization
- WordPress core installation
- `wp-config.php` generation
- database users and WordPress users
- data written to persistent volumes

The key idea is: images define infrastructure, containers manage state.

### PID 1 and Foreground Processes

A container stays alive while its main process, PID 1, is alive. Docker sends signals such as `SIGTERM` to PID 1 when stopping containers.

In this project:

| Container | Main process |
| --- | --- |
| `mariadb` | `mariadbd --console` |
| `wordpress` | `php-fpm8.2 -F` |
| `nginx` | `nginx -g 'daemon off;'` |

Entrypoint scripts must finish with `exec "$@"` so the real service replaces the shell and becomes PID 1. This improves signal handling and clean shutdown.

### Forbidden Keep-Alive Patterns

The containers must not be kept alive with fake loops such as:

```bash
while true; do sleep 1; done
```

They must also not daemonize their main process in the background. Temporary background processes are acceptable only during initialization, as MariaDB does while creating the first database state, and they must be stopped before the final foreground process starts.

## Applied Architecture

### Project Structure

```text
inception/
├── Makefile
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
├── secrets/
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf
        │   └── tools/mariadb-entrypoint.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/default.conf
        │   └── tools/nginx-entrypoint.sh
        └── wordpress/
            ├── Dockerfile
            └── tools/wordpress-entrypoint.sh
```

### Service Roles

`mariadb` is the data layer. Its image installs MariaDB, copies `50-server.cnf`, and starts through `mariadb-entrypoint.sh`. The configuration binds MariaDB to `0.0.0.0` so WordPress can connect through the Docker bridge network, while the database remains unexposed to the host.

`wordpress` is the application layer. Its image installs PHP-FPM, required PHP extensions, MariaDB client tools, and WP-CLI. WordPress is installed at runtime into `/var/www/html`, which is backed by the persistent WordPress volume.

`nginx` is the only public entrypoint. It listens on HTTPS port `443`, uses a self-signed certificate, serves files from `/var/www/html`, and forwards PHP requests to `wordpress:9000` using FastCGI.

### Startup Flow

When the stack starts:

1. Docker Compose creates the `inception` bridge network.
2. Images are built if needed.
3. `mariadb` starts and initializes `/var/lib/mysql` if empty.
4. `wordpress` waits until MariaDB is reachable, then installs/configures WordPress if needed.
5. `nginx` starts and serves HTTPS traffic.

`depends_on` controls start order, but it does not prove that MariaDB is ready. The WordPress entrypoint handles readiness by waiting for MariaDB before running WP-CLI.

### Network and Volumes

Only NGINX exposes a host port:

```text
443 -> 443
```

Internal services remain private:

```text
nginx -> wordpress:9000 -> mariadb:3306
```

Persistent bind-backed Docker volumes:

| Volume | Host path | Container path |
| --- | --- | --- |
| `mariadb_data` | `/home/natferna/data/mariadb` | `/var/lib/mysql` |
| `wordpress_data` | `/home/natferna/data/wordpress` | `/var/www/html` |

### Docker Compose Directives

Important directives used in `srcs/docker-compose.yml`:

| Directive | Role |
| --- | --- |
| `build` | Points to each custom Dockerfile. |
| `image` | Names the locally built project image. |
| `container_name` | Gives stable container names for inspection. |
| `env_file` | Loads non-sensitive configuration from `srcs/.env`. |
| `secrets` | Mounts password files under `/run/secrets`. |
| `volumes` | Mounts persistent data into containers. |
| `networks` | Connects services to the private `inception` network. |
| `depends_on` | Defines startup order. |
| `restart: always` | Restarts services if they fail. |

## WordPress and MariaDB Data Model

`wp-config.php` is generated at runtime by WP-CLI and stored in the WordPress volume. It contains:

- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_HOST`, which points to `mariadb:3306`
- authentication keys and salts
- table prefix, normally `wp_`

Even when the database password starts as a Docker secret, WordPress needs it as a PHP constant in `wp-config.php` at runtime. Secrets protect startup configuration; WordPress still stores the database password in its persistent configuration file.

Important database tables:

| Table | Purpose |
| --- | --- |
| `wp_users` | WordPress users. |
| `wp_usermeta` | Roles and capabilities. |
| `wp_posts` | Posts, pages, revisions, and attachments. |
| `wp_options` | Site URL, home URL, and global settings. |
| `wp_comments` | Comments. |

## Inspection and Testing

### Clean State Check

Before a full rebuild:

```bash
make fclean
docker ps -a
docker images
docker volume ls
```

Expected project resources after `make fclean`:

- no `nginx`, `wordpress`, or `mariadb` containers
- no `inception-*` images
- no `mariadb_data` or `wordpress_data` volumes

Start again:

```bash
make
docker ps
```

Expected containers:

```text
mariadb
wordpress
nginx
```

### Network Verification

```bash
docker network ls
docker network inspect inception
docker exec wordpress getent hosts mariadb
docker exec nginx getent hosts wordpress
```

Expected result: services resolve each other by container/service name through Docker DNS.

### Volume Verification

```bash
docker volume ls
docker volume inspect mariadb_data
docker volume inspect wordpress_data
ls -l /home/natferna/data
```

Expected host directories:

```text
/home/natferna/data/mariadb
/home/natferna/data/wordpress
```

### MariaDB Verification

```bash
docker exec -it mariadb bash
mariadb -u root -p
```

Useful SQL checks:

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT ID, user_login, user_email FROM wp_users;
SELECT user_id, meta_key, meta_value FROM wp_usermeta WHERE meta_key LIKE '%capabilities%';
SELECT ID, post_title, post_type, post_status FROM wp_posts;
```

Application users are created with host-based grants such as `'user'@'%'`, allowing WordPress to connect from the Docker network.

### WordPress Verification

```bash
docker exec -it wordpress bash
ls /var/www/html
wp user list --allow-root --path=/var/www/html
wp option get siteurl --allow-root --path=/var/www/html
wp option get home --allow-root --path=/var/www/html
```

Expected URL values:

```text
https://natferna.42.fr
```

### NGINX and HTTPS Verification

From inside the VM:

```bash
curl -k https://localhost
openssl s_client -connect localhost:443 -servername natferna.42.fr
```

From the Linux host, after domain resolution is configured:

```bash
curl -k https://natferna.42.fr
```

Inspect NGINX configuration and logs:

```bash
docker exec nginx nginx -T
docker exec nginx cat /var/log/nginx/access.log
docker exec nginx cat /var/log/nginx/error.log
```

Expected TLS protocols:

```text
TLSv1.2 TLSv1.3
```

### Persistence Test

1. Create or edit a WordPress post/user through the browser.
2. Restart the stack:

```bash
make down
make
```

3. Reopen WordPress and verify the data still exists.

This confirms that MariaDB and WordPress data survive container removal and rebuilds.

### Restart and Security Checks

Check restart policy:

```bash
docker inspect nginx | grep -A 5 RestartPolicy
docker inspect wordpress | grep -A 5 RestartPolicy
docker inspect mariadb | grep -A 5 RestartPolicy
```

Check mounted secrets:

```bash
docker exec mariadb ls /run/secrets
docker exec wordpress ls /run/secrets
```

Check that passwords are not exposed as normal environment variables:

```bash
docker inspect mariadb | grep -i password
docker inspect wordpress | grep -i password
```

A clean shutdown should normally exit with code `0`; exit code `137` indicates a forced kill.

## Defense Notes

NGINX is the only public entrypoint because the subject requires access only through port 443. WordPress and MariaDB are isolated on the internal Docker network.

Each container runs one main foreground process:

- NGINX runs with `daemon off`.
- WordPress runs `php-fpm8.2 -F`.
- MariaDB runs `mariadbd --console`.

No container is kept alive with an infinite loop such as `tail -f`, `sleep infinity`, or `while true`.
