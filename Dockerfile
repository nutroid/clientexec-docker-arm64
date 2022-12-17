FROM arm64v8/alpine:latest

LABEL Maintainer="Sayak B <me@sayakb.com>" \
      Description="Clientexec for ARM64 with Nginx based on Alpine Linux"

ARG GID=100
ARG UID=101

# Install packages and remove default server definition
RUN apk --no-cache add php81 php81-gd php81-pecl-mcrypt apache2 php81-ctype \
    php81-curl php81-openssl php81-mbstring php81-pdo php81-soap php81-pdo_mysql \
    php81-mysqli php81-imap php81-iconv supervisor curl shadow php81-simplexml wget \
    php81-apache2 php81-session --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

# Download ioncube
RUN cd /tmp \
    && curl -sSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz -o ioncube.tar.gz \
    && tar -xf ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_8.1.so /usr/lib/php81/modules/ioncube_loader_lin_8.1.so \
    && echo 'zend_extension = /usr/lib/php81/modules/ioncube_loader_lin_8.1.so' > /etc/php81/conf.d/00-ioncube.ini \
    && rm ioncube.tar.gz

# Copy configs
COPY config/php.ini /etc/php81/conf.d/custom.ini

# Create root directory
RUN mkdir -p /htdocs
RUN mkdir -p /dl
COPY config/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set up PHP8.1 as default PHP
RUN ln -s /usr/bin/php81 /usr/bin/php

# Change working directory
WORKDIR /dl

# Download clientexec
RUN curl -Lo clientexec.zip https://www.clientexec.com/download/latest \
    && unzip clientexec.zip \
    && rm clientexec.zip

# Expose the port apache is reachable on
EXPOSE 80

# Run as non-root user
RUN chown -R apache.apache /dl \
    && chown -R apache.apache /htdocs

# Add the cron job
RUN crontab -l | { cat; echo "* * * * * php -q /htdocs/cron.php"; } | crontab -

# Execute scripts on start
ENTRYPOINT ["/entrypoint.sh"]

# Healthcheck
HEALTHCHECK CMD wget -q --no-cache --spider localhost
