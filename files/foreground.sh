#!/bin/bash

# check dir and permission
echo "placeholder" > /var/www/html/glpi/plugins/placeholder
for dir in _cache  _cron  _dumps  _graphs  _lock  _log  _pictures  _plugins  _rss  _sessions  _tmp  _uploads
do
	mkdir /var/www/html/glpi/files/$dir
done

chown -R www-data:www-data /var/www/html/glpi/{files,plugins}
chmod 755 /var/www/html/glpi/{files,plugins}


read pid cmd state ppid pgrp session tty_nr tpgid rest < /proc/self/stat
trap "kill -TERM -$pgrp; exit" EXIT TERM KILL SIGKILL SIGTERM SIGQUIT

#start up cron
/usr/sbin/cron
#start up apache
source /etc/apache2/envvars
exec apache2 -D FOREGROUND
