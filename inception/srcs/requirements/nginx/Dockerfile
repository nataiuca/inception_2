FROM debian:bookworm

ARG DOMAIN_NAME

RUN apt-get update \
	&& apt-get install -y --no-install-recommends nginx openssl ca-certificates \
	&& rm -rf /var/lib/apt/lists/* /var/www/html/*

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY tools/nginx-entrypoint.sh /usr/local/bin/nginx-entrypoint.sh

RUN chmod +x /usr/local/bin/nginx-entrypoint.sh \
	&& mkdir -p /etc/nginx/ssl \
	&& openssl req -x509 -nodes -days 365 \
		-newkey rsa:4096 \
		-keyout /etc/nginx/ssl/inception.key \
		-out /etc/nginx/ssl/inception.crt \
		-subj "/CN=${DOMAIN_NAME}"

EXPOSE 443

ENTRYPOINT ["nginx-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
