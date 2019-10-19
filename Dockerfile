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
	sed -ri 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g;' /etc/apache2/sites-available/*.conf && \
	a2enmod rewrite && a2enmod ssl && a2ensite default-ssl && a2enconf zz_apache-glpi 
#
RUN echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf && chmod 0644 /etc/cron.d/glpicron && chmod +x /etc/apache2/foreground.sh

# PLUGINS
RUN plugins="https://forge.glpi-project.org/attachments/download/2296/glpi-behaviors-2.2.2.tar.gz \
         https://forge.glpi-project.org/attachments/download/2294/GLPI-dashboard_plugin-0.9.8.zip \
         https://forge.glpi-project.org/attachments/download/2195/plugin-webnotifications-1.1.3.tar.gz \
         https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.4%2B1.1/fusioninventory-9.4+1.1.tar.bz2 \
         https://github.com/stdonato/glpi-modifications/archive/1.5.1.tar.gz \
         https://github.com/pluginsGLPI/escalade/releases/download/2.4.4/glpi-escalade-2.4.4.tar.bz2" && \
    rm -rf /tmp/* && cd /tmp && for URL in $(echo $plugins) ; do wget $URL ; done && extract () { if [ -f $1 ] ; then case $1 in *.tar.bz2) tar xjf $1;; *.tar.gz) tar xzf $1;; *.bz2) bunzip2 $1;; *.rar) rar x $1;; *.gz) gunzip $1;; *.tar) tar xf $1;; *.tbz2) tar xjf $1;; *.tgz) tar xzf $1 ;; *.zip) unzip $1 ;; *.Z) uncompress $1 ;; *) echo "'$1' cannot be extracted via extract()" ;; esac; else  echo "'$1' is not a valid file"; fi; } && cd /var/www/html/glpi/plugins/ && for i in /tmp/* ; do extract $i; done && mv glpi-modifications-1.5.1 mod && chown -R www-data:www-data /var/www/html 


# Cleanup, this is ran to reduce the resulting size of the image.
RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/cache/* /var/lib/log/* /var/lib/apt/lists/*

#Puertos y Volumenes
VOLUME ["/var/www/html/glpi/plugins", "/var/www/html/glpi/files" ]
EXPOSE 80 443
ENTRYPOINT ["/etc/apache2/foreground.sh"]