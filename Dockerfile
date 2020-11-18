FROM php:7.2-apache

RUN apt-get update && apt-get install -qqy git unzip libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libaio1 wget && apt-get clean autoclean && apt-get autoremove --yes &&  rm -rf /var/lib/{apt,dpkg,cache,log}/ 

###########################################################
### ORACLE oci 
###########################################################
RUN mkdir /opt/oracle \
    && cd /opt/oracle
 
ADD instantclient-basic-linux.x64-12.2.0.1.0.zip /opt/oracle
ADD instantclient-sdk-linux.x64-12.2.0.1.0.zip /opt/oracle

# Install Oracle Instantclient
RUN  unzip /opt/oracle/instantclient-basic-linux.x64-12.2.0.1.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /opt/oracle \
    && ln -s /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so \
    && ln -s /opt/oracle/instantclient_12_2/libclntshcore.so.12.1 /opt/oracle/instantclient_12_2/libclntshcore.so \
    && ln -s /opt/oracle/instantclient_12_2/libocci.so.12.1 /opt/oracle/instantclient_12_2/libocci.so \
    && rm -rf /opt/oracle/*.zip
    
ENV LD_LIBRARY_PATH  /opt/oracle/instantclient_12_2:${LD_LIBRARY_PATH}

###########################################################
### Install Oracle extensions
###########################################################  
RUN echo 'instantclient,/opt/oracle/instantclient_12_2/' | pecl install oci8 \ 
      && docker-php-ext-enable \
               oci8 \ 
       && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_2,12.1 \
       && docker-php-ext-install \
               pdo_oci 


###########################################################
### Configure PHP
###		- Install GD
###		- Install Intl
###		- Install Composer
###		- Install mbstring
###		- Install SOAP
###		- Install opcache
###		- Install PHP zip extension
###		- Install XSL
###########################################################
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev && \
	docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
	docker-php-ext-install gd && \
	apt-get install -y libicu-dev && \
	docker-php-ext-install intl && \
    curl -sS https://getcomposer.org/installer | php && \
	mv composer.phar /usr/local/bin/composer && \
	docker-php-ext-install mbstring && \
	apt-get install -y libxml2-dev && \
	docker-php-ext-install soap && \
	docker-php-ext-install opcache && \
	docker-php-ext-install zip && \
	apt-get install -y libxslt-dev && \
	docker-php-ext-install xsl && \
    apt-get install nano

###########################################################
### Apache Configuration
###########################################################
ENV APACHE_DOC_ROOT /var/www/html
RUN a2enmod rewrite && \
	usermod -u 1000 www-data && \
	groupmod -g 1000 www-data

###########################################################
### Give ownership to code
###########################################################	
RUN usermod -aG www-data www-data
RUN chown -R www-data:www-data /var/www

###########################################################
### Start Apache Service
###########################################################
CMD apachectl -D FOREGROUND
