#!/bin/sh

DIR="/var/www/html"

# If dir is empty, copy clientexec application into webroot
if [ "$(ls -A $DIR)" ]; then
    echo "$DIR is not empty, skipping"
else
    echo "Initializing clientexec"
    cp -R /var/www/clientexec/. /var/www/html
fi

exec "$@"
