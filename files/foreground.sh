#!/bin/bash

# turn on bash's job control
set -m

#######
# clean old pid and "fix" cron
find /var/run/ -type f -iname \*.pid -delete
touch /etc/crontab  /etc/cron.d/php /etc/cron.d/moodlecron

#######
# timezone
if test -v TZ && [ `readlink /etc/localtime` != "/usr/share/zoneinfo/$TZ" ]; then
  if [ -f /usr/share/zoneinfo/$TZ ]; then
    echo $TZ > /etc/timezone 
    rm /etc/localtime 
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime 
    dpkg-reconfigure -f noninteractive tzdata 

    echo "date.timezone=$TZ" > /etc/php/7.2/apache2/conf.d/99_datatime.ini 
  fi
fi

# disable LDAP valid TLS cert
if test -v GLPI_TLSNEVER; then
	echo "TLS_REQCERT   never" >> /etc/ldap/ldap.conf
fi

###################
DIRPLUGIN=/opt/glpi/plugins/
DIRGLPI=/var/www/html/glpi/

# check dir and permission
mkdir -p $DIRGLPI/plugins
echo "placeholder" > $DIRGLPI/plugins/placeholder

test -d $DIRGLPI/plugins/dashboard || cd $DIRGLPI/plugins/ ; unzip $DIRPLUGIN/GLPI-dashboard_plugin-0.9.8.zip  
test -d $DIRGLPI/plugins/behaviors || cd $DIRGLPI/plugins/ ; tar zxvf $DIRPLUGIN/glpi-behaviors-2.2.2.tar.gz  
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

if test -v GLPI_INSTALLED; then
   mv /var/www/html/glpi/install/install.php /var/www/html/glpi/install/install.php.old
fi

if test -v GLPI_DATABASE_HOST; then
  
echo "<?php
class DB extends DBmysql {
   public \$dbhost     = '$GLPI_DATABASE_HOST';
   public \$dbuser     = '$GLPI_DATABASE_USER';
   public \$dbpassword = '$GLPI_DATABASE_PASS';
   public \$dbdefault  = '$GLPI_DATABASE_NAME';
}" > /var/www/html/glpi/config/config_db.php

fi

###################
#start up cron
/usr/sbin/cron
#start up apache
source /etc/apache2/envvars
exec apache2 -D FOREGROUND
