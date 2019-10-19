#!/bin/bash

echo "placeholder" > /var/www/html/plugins/placeholder
chown -R www-data:www-data /var/www/html/plugins
chmod 755 /var/www/html/plugins

read pid cmd state ppid pgrp session tty_nr tpgid rest < /proc/self/stat
trap "kill -TERM -$pgrp; exit" EXIT TERM KILL SIGKILL SIGTERM SIGQUIT

#start up cron
/usr/sbin/cron


source /etc/apache2/envvars
exec apache2 -D FOREGROUND
