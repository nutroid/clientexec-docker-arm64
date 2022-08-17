FROM arm64v8/alpine:3.16.2

LABEL Maintainer="Sayak B <me@sayakb.com>" \
      Description="Clientexec for ARM64 with Nginx based on Alpine Linux"

ARG GID=100
ARG UID=101

# Install packages and remove default server definition
RUN apk --no-cache add php7 php7-gd php7-pecl-mcrypt apache2 php7-json php7-ctype \
    php7-curl php7-openssl php7-mbstring php7-pdo php7-soap php7-pdo_mysql \
    php7-mysqli php7-imap php7-iconv supervisor curl shadow php7-simplexml wget \
    php7-apache2 php7-session --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

# Download ioncube
RUN cd /tmp \
    && curl -sSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz -o ioncube.tar.gz \
    && tar -xf ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_7.4.so /usr/lib/php7/modules/ioncube_loader_lin_7.4.so \
    && echo 'zend_extension = /usr/lib/php7/modules/ioncube_loader_lin_7.4.so' > /etc/php7/conf.d/00-ioncube.ini \
    && rm ioncube.tar.gz

# Copy configs
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Create root directory
RUN mkdir -p /htdocs
RUN mkdir -p /dl
COPY config/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set up PHP7 as default PHP
RUN ln -s /usr/bin/php7 /usr/bin/php

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
RUN crontab -l | { cat; echo "* * * * * /usr/bin/php -q /htdocs/cron.php"; } | crontab -

# Execute scripts on start
ENTRYPOINT ["/entrypoint.sh"]

# Healthcheck
HEALTHCHECK CMD wget -q --no-cache --spider localhost
