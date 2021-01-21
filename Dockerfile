# base
FROM ubuntu:18.04
LABEL maintainer="Pablo A. Vargas <pablo@pampa.cloud>"

# Environment
ENV DEBIAN_FRONTEND noninteractive

# update & upgrade & install base
RUN apt update && apt -y dist-upgrade \
&& apt -y install apache2 php php-mysql php-ldap php-xmlrpc php-imap curl php-curl php-gd php-mbstring php-xml php-apcu-bc php-cas cron wget unzip 

#
COPY files/foreground.sh /etc/apache2/foreground.sh
COPY files/glpicron /etc/cron.d/glpicron
COPY files/apache-glpi.conf /etc/apache2/conf-available/zz_apache-glpi.conf
COPY files/glpi-php.ini /etc/php/7.2/apache2/conf.d/glpi-php.ini
#
RUN cd /tmp && wget https://github.com/glpi-project/glpi/releases/download/9.4.4/glpi-9.4.4.tgz && \
	tar -zxvf glpi-9.4.4.tgz && mv /tmp/glpi /var/www/html/ && rm -rf /var/www/html/index.html && touch /var/www/html/index.html && \
	sed -ri 's!^(\s*CustomLog)\s+\S+!\1 /dev/stdout!g; s!^(\s*ErrorLog)\s+\S+!\1 /dev/stdout!g;' /etc/apache2/sites-available/*.conf && \
	a2enmod rewrite && a2enmod ssl && a2ensite default-ssl && a2enconf zz_apache-glpi 
#
RUN echo "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf && chmod 0644 /etc/cron.d/glpicron && chmod +x /etc/apache2/foreground.sh

# PLUGINS DOWNLOADS
RUN plugins="https://forge.glpi-project.org/attachments/download/2296/glpi-behaviors-2.2.2.tar.gz \
         https://forge.glpi-project.org/attachments/download/2294/GLPI-dashboard_plugin-0.9.8.zip \
         https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.4%2B1.1/fusioninventory-9.4+1.1.tar.bz2 \
         https://github.com/stdonato/glpi-modifications/archive/1.5.1.tar.gz \
         https://github.com/pluginsGLPI/escalade/releases/download/2.4.4/glpi-escalade-2.4.4.tar.bz2" && \
         mkdir -p /opt/glpi/plugins && cd /opt/glpi/plugins && for URL in $(echo $plugins) ; do wget $URL; done && chown -R www-data:www-data /var/www/html/glpi && chmod 755 /var/www/html/glpi


# Cleanup, this is ran to reduce the resulting size of the image.
RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/cache/* /var/lib/log/* /var/lib/apt/lists/*

#Puertos y Volumenes
VOLUME ["/var/www/html/glpi/plugins", "/var/www/html/glpi/files", "/var/www/html/glpi/css" ]
EXPOSE 80 443
ENTRYPOINT ["/etc/apache2/foreground.sh"]
