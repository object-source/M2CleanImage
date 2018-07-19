FROM tetraweb/php:7.1

MAINTAINER ObjectSource <team@objectsource.co.uk>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssh-client \
    git-core \
    mysql-client \
    libbz2-dev \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libxslt1-dev \
    libxml2-dev \
    libgd2-xpm-dev && \
    rm -r /var/lib/apt/lists/*

# PHP Extensions (curl, mbstring, hash, simplexml, xml, json, iconv are already installed in php image)
RUN docker-php-ext-configure \
  gd --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install \
    gd \
    mbstring \
    curl \
    soap \
    bcmath \
    bz2 \
    intl \
    mcrypt \
    pdo_mysql \
    soap \
    xsl \
    zip

# PHP Configuration
RUN echo "memory_limit=-1" > $PHP_INI_DIR/conf.d/memory-limit.ini
RUN echo "date.timezone=Europe/London" > $PHP_INI_DIR/conf.d/date_timezone.ini

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
