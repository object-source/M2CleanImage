FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

# Update repositories
RUN apt-get update

# Install system apps
RUN apt-get -o Dpkg::Options::=--force-confdef -y install rsync gnupg2 supervisor curl wget telnet vim git locales software-properties-common apt-utils unzip build-essential \
      && locale-gen en_GB.utf8 
     

# Install nginx
RUN apt-get install --no-install-recommends --no-install-suggests -y \
						ca-certificates \
						nginx \
						gettext-base \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && sed -i -e 's/gzip on/#gzip on/' /etc/nginx/nginx.conf \
    && sed -i -e 's/gzip_disable/#gzip_disable/' /etc/nginx/nginx.conf \
    && rm /etc/nginx/sites-available/* /etc/nginx/sites-enabled/default \
    && mkdir -p /var/www/html \
    && chmod 777 /var/www/html /var/lib/nginx \
    && chmod 755 /var/www 

# Install PHP 7.2
RUN add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y php7.2-cli php7.2-fpm php7.2-common php7.2-curl php7.2-gd php7.2-mysql php7.2-soap php7.2-xml php7.2-zip php7.2-gettext php7.2-mbstring php7.2-intl php7.2-imap php7.2-bcmath php-imagick php-xdebug \
    && sed -i -e 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/7.2/fpm/php.ini \
    && sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php/7.2/fpm/php.ini \
    && sed -i -e 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php/7.2/fpm/php.ini \
    && sed -i -e 's/memory_limit = 128M/memory_limit = 2G/g' /etc/php/7.2/fpm/php.ini \
    && sed -i -e '/sendfile on;/a\        fastcgi_read_timeout 300\;' /etc/nginx/nginx.conf \
    && sed -i -e 's/;php_admin_value\[error_log\]/php_admin_value[error_log]/' /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -i -e 's/;php_admin_flag\[log_errors\]/php_admin_flag[log_errors]/' /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -i -e 's/;php_admin_value\[memory_limit\] = 32M/php_admin_value[memory_limit] = 2G/' /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -i -e 's/pm\.max_children = 5/pm.max_children = 10/' /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -i -e 's/pm\.start_servers = 2/pm.start_servers = 4/' /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -i -e 's/pm\.min_spare_servers = 1/pm.min_spare_servers = 2/' /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -i -e 's/pm\.max_spare_servers = 3/pm.max_spare_servers = 6/' /etc/php/7.2/fpm/pool.d/www.conf \
    && echo "xdebug.max_nesting_level = 200;" >> /etc/php/7.2/mods-available/xdebug.ini \
    && echo "xdebug.remote_enable = on;" >> /etc/php/7.2/mods-available/xdebug.ini \
    && echo "xdebug.remote_connect_back = on;" >> /etc/php/7.2/mods-available/xdebug.ini \
    && echo "xdebug.remote_port = 9000;" >> /etc/php/7.2/mods-available/xdebug.ini \
    && echo "xdebug.idekey = PHP_STORM;" >> /etc/php/7.2/mods-available/xdebug.ini \
    && phpdismod -s cli xdebug \
    && mkdir --mode 777 /var/run/php

# Install ioncube
RUN mkdir -p /usr/src/tmp/ioncube \
    && curl -fSL "http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz" -o /usr/src/tmp/ioncube_loaders_lin_x86-64.tar.gz \
    && tar xfz /usr/src/tmp/ioncube_loaders_lin_x86-64.tar.gz -C /usr/src/tmp/ioncube \
    && cp /usr/src/tmp/ioncube/ioncube/ioncube_loader_lin_7.2.so /usr/lib/php/20151012/ \
    && rm -rf /usr/src/tmp/

# Install WP-CLI
RUN mkdir /tmp/wpcli/ \
    && cd /tmp/wpcli \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp-cli \
    && rm -rf /tmp/wpcli

# Install nodejs
ENV NVM_DIR /root/.nvm
ENV NODE_VERSION 11.10.1

RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | sh \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION 

RUN echo 'export NVM_DIR="/root/.nvm"'                                       >> "/root/.bashrc"
RUN echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> "/root/.bashrc"
RUN echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" # This loads nvm bash_completion' >> "/root/.bashrc"
RUN /bin/bash -c "source /root/.bashrc"

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

## yarn
RUN npm -g install yarn
RUN npm install -g gulp-cli

# Clean up
RUN apt-get autoremove -y \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /usr/local/bin/*

VOLUME /root/composer

# Environmental Variables
ENV COMPOSER_HOME /root/composer

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
	composer selfupdate

# Goto temporary directory.
WORKDIR /tmp


RUN php --version
RUN composer --version
RUN composer global require hirak/prestissimo
