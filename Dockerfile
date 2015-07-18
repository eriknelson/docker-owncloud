###############################################################################
FROM eriknelson/lamp
MAINTAINER eriknelson <io@eriknelson.me>
# NOTE: Forked from upstream - https://registry.hub.docker.com/u/l3iggs/owncloud
################################################################################
# TODO: Permissions issue with volumes being mounted as root into the container
# Causes apache to be unable to access /usr/share/webapps/owncloud/config
# As temporary fix, can log into the running container and change permissions afer
# launching it, but this is not ideal. Need strategic way to deal with this.
################################################################################

# update package list
RUN pacman -Syy

# set environmnt variable defaults
ENV REGENERATE_SSL_CERT false
ENV START_APACHE true
ENV START_MYSQL true
ENV MAX_UPLOAD_SIZE 30G
ENV TARGET_SUBDIR owncloud

# remove info.php
RUN rm /srv/http/info.php

# to mount SAMBA shares:
RUN pacman -S --noconfirm --needed smbclient

# for video file previews
RUN pacman -S --noconfirm --needed ffmpeg

# for document previews
RUN pacman -S --noconfirm --needed libreoffice-fresh

# Install owncloud
RUN pacman -S --noconfirm --needed owncloud

# Install owncloud addons
RUN pacman -S --noconfirm --needed owncloud-app-bookmarks
RUN pacman -S --noconfirm --needed owncloud-app-calendar
RUN pacman -S --noconfirm --needed owncloud-app-contacts
RUN pacman -S --noconfirm --needed owncloud-app-documents
RUN pacman -S --noconfirm --needed owncloud-app-gallery

# enable large file uploads
RUN sed -i "s,php_value upload_max_filesize 513M,php_value upload_max_filesize ${MAX_UPLOAD_SIZE},g" /usr/share/webapps/owncloud/.htaccess
RUN sed -i "s,php_value post_max_size 513M,php_value post_max_size ${MAX_UPLOAD_SIZE},g" /usr/share/webapps/owncloud/.htaccess
RUN sed -i 's,<IfModule mod_php5.c>,<IfModule mod_php5.c>\nphp_value output_buffering Off,g' /usr/share/webapps/owncloud/.htaccess

# setup Apache for owncloud
RUN cp /etc/webapps/owncloud/apache.example.conf /etc/httpd/conf/extra/owncloud.conf
RUN sed -i '/<VirtualHost/,/<\/VirtualHost>/d' /etc/httpd/conf/extra/owncloud.conf
RUN sed -i 's,Alias /owncloud /usr/share/webapps/owncloud/,Alias /${TARGET_SUBDIR} /usr/share/webapps/owncloud/,g' /etc/httpd/conf/extra/owncloud.conf
RUN sed -i 's,Options Indexes FollowSymLinks,Options -Indexes +FollowSymLinks,g' /etc/httpd/conf/httpd.conf
RUN sed -i '$a Include conf/extra/owncloud.conf' /etc/httpd/conf/httpd.conf
RUN chown -R http:http /usr/share/webapps/owncloud/

# configure PHP open_basedir
RUN sed -i 's,^open_basedir.*$,\0:/usr/share/webapps/owncloud/:/usr/share/webapps/owncloud/config/:/etc/webapps/owncloud/config/,g' /etc/php/php.ini

################################################################################
# TODO: These seem to be problematic, especially the apps mount
# Upon mount, the apps directory looks like it gets clobbered, after sign in
# when owncloud goes to load, there's nothingin the directory to load and we're
# presented with an empty screen. Canonical approach to this?
# See: https://github.com/l3iggs/docker-owncloud/issues/23
################################################################################
#VOLUME ["/usr/share/webapps/owncloud/data"]
#VOLUME ["/etc/webapps/owncloud/config"]
#VOLUME ["/usr/share/webapps/owncloud/apps"]
# place your ssl cert files in here. name them server.key and server.crt
#VOLUME ["/https"]
################################################################################

# start servers
CMD ["/root/startServers.sh"]
