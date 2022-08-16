FROM arm64v8/alpine:3.16.2

LABEL Maintainer="Sayak B <me@sayakb.com>" \
      Description="Clientexec for ARM64 with Nginx based on Alpine Linux"

ARG GID=1000
ARG UID=1000

# Install packages and remove default server definition
RUN apk --no-cache add php7 php7-gd php7-pecl-mcrypt php7-fpm php7-json \
    php7-curl php7-openssl php7-mbstring php7-pdo php7-soap php7-pdo_mysql \
    php7-mysqli php7-imap php7-iconv supervisor curl shadow nginx php7-simplexml \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

# Download ioncube
RUN cd /tmp \
    && curl -sSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz -o ioncube.tar.gz \
    && tar -xf ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_7.4.so /usr/lib/php7/modules/ioncube_loader_lin_7.4.so \
    && echo 'zend_extension = /usr/lib/php7/modules/ioncube_loader_lin_7.4.so' > /etc/php7/conf.d/00-ioncube.ini \
    && rm ioncube.tar.gz

# Copy configs
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create root directory
RUN mkdir -p /var/www/html
COPY config/entrypoint.sh /var/www/entrypoint.sh
RUN chmod +x /var/www/entrypoint.sh

# Change UID and GID of nobody to 1000 to match most host user's IDs
RUN usermod -u ${UID} nobody && groupmod -g ${GID} nobody

# Run as non-root user
RUN chown -R nobody.nobody /var/www \
    && chown -R nobody.nobody /run \
    && chown -R nobody.nobody /var/lib/nginx \
    && chown -R nobody.nobody /var/log/nginx

# Switch to non-root user
USER nobody

# Change working directory
WORKDIR /var/www

# Download clientexec
RUN curl -Lo clientexec.zip https://www.clientexec.com/download/latest \
    && unzip clientexec.zip \
    && rm clientexec.zip

# Expose the port nginx is reachable on
EXPOSE 8080

# Execute scripts on start
ENTRYPOINT ["/var/www/entrypoint.sh"]

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Healthcheck
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
