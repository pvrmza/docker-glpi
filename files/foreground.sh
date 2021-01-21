#!/bin/bash


DIRPLUGIN=/opt/glpi/plugins/
DIRGLPI=/var/www/html/glpi/

# check dir and permission
mkdir -p $DIRGLPI/plugins
echo "placeholder" > $DIRGLPI/plugins/placeholder

test -d $DIRGLPI/plugins/behaviors || cd $DIRGLPI/plugins/ ; tar zxvf $DIRPLUGIN/glpi-behaviors-2.2.2.tar.gz  
test -d $DIRGLPI/plugins/dashboard || cd $DIRGLPI/plugins/ ; unzip $DIRPLUGIN/GLPI-dashboard_plugin-0.9.8.zip  
test -d $DIRGLPI/plugins/escalade ||  cd $DIRGLPI/plugins/ ; tar xjf $DIRPLUGIN/glpi-escalade-2.4.4.tar.bz2 
test -d $DIRGLPI/plugins/fusioninventory ||  cd $DIRGLPI/plugins/ ; tar xjf $DIRPLUGIN/fusioninventory-9.4+1.1.tar.bz2
test -d $DIRGLPI/plugins/mod ||  cd $DIRGLPI/plugins/ ; tar zxvf $DIRPLUGIN/1.5.1.tar.gz ; mv glpi-modifications-1.5.1 mod

#
for dir in _cache  _cron  _dumps  _graphs  _lock  _log  _pictures  _plugins  _rss  _sessions  _tmp  _uploads
do
	mkdir -p /var/www/html/glpi/files/$dir
done
#
chown -R www-data:www-data /var/www/html/glpi/{files,plugins,css}
chmod 755 /var/www/html/glpi/{files,plugins,css}

if [ -z ${TIMEZONE+x} ]; then 
   echo "TIMEZONE is unset"; 
else 
   echo "date.timezone = \"$TIMEZONE\"" > /etc/php/7.2/apache2/conf.d/timezone.ini;
fi

if [ -z ${GLPI_INSTALLED+x} ]; then 
   echo "GLPI_INSTALLED is unset"; 
else 
   mv /var/www/html/glpi/install/install.php /var/www/html/glpi/install/install.php.old
fi

read pid cmd state ppid pgrp session tty_nr tpgid rest < /proc/self/stat
trap "kill -TERM -$pgrp; exit" EXIT TERM KILL SIGKILL SIGTERM SIGQUIT

#start up cron
/usr/sbin/cron
#start up apache
source /etc/apache2/envvars
exec apache2 -D FOREGROUND
