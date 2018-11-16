FROM ubuntu:18.04

LABEL maintainer="Lucas van Staden lucas.vanstaden@enjo.com.au"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y install software-properties-common tzdata

RUN add-apt-repository ppa:ondrej/php
RUN apt-get update && apt -y upgrade

RUN apt-get install -y --no-install-recommends \
	build-essential \
	software-properties-common \
	cron \
	nano \
	git \
	curl \
	supervisor \
    php7.1-cli \
    php7.1-mysql \
    php7.1-curl \
    php7.1-mcrypt \
    php7.1-gd \
    php7.1-redis \
    php7.1-xml \
    php7.1-soap \
    php7.1-mbstring \
    php7.1-zip \
    php7.2-fpm \
    php7.2-cli \
    php7.2-mysql \
    php7.2-curl \
    php7.2-gd \
    php7.2-redis \
    php7.2-xml \
    php7.2-soap \
    php7.2-mbstring \
    php7.2-zip \
	nginx \
	ssh \
	npm \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD nginx/default   /etc/nginx/sites-available/default
ADD nginx/.htpasswd   /etc/nginx/

# Install nodejs
RUN npm install express serve-static

# Install ssh key
RUN mkdir -p /root/.ssh/ && touch /root/.ssh/known_hosts

# Install Composer
# Install prestissimo
# Install Satis and Satisfy
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
	&& /usr/local/bin/composer global require hirak/prestissimo
RUN mkdir /satisfy && chmod -R 777 /satisfy && rm -rf /root/.composer/cache/*
RUN git clone https://github.com/ProxiBlue/satisfy.git /satisfy && cd /satisfy && composer install

ADD scripts /app/scripts

ADD scripts/crontab /etc/cron.d/satis-cron
ADD satis.json /root/satis.json
ADD server.js /app/server.js
RUN chmod 0644 /etc/cron.d/satis-cron \
	&& touch /var/log/satis-cron.log \
	&& chmod 777 /root/config.json \
	&& chmod 777 /app/server.js \
	&& chmod +x /app/scripts/startup.sh

ADD supervisor/0-install.conf /etc/supervisor/conf.d/0-install.conf
ADD supervisor/1-cron.conf /etc/supervisor/conf.d/1-cron.conf
ADD supervisor/2-nginx.conf /etc/supervisor/conf.d/2-nginx.conf
ADD supervisor/3-php.conf /etc/supervisor/conf.d/3-php.conf
ADD supervisor/4-node.conf /etc/supervisor/conf.d/4-node.conf

RUN sed -i '/^;catch_workers_output/ccatch_workers_output = yes' "/etc/php/7.2/fpm/pool.d/www.conf"

RUN mkdir /satisfy/app/../var/cache/dev -p && chmod 777 /satisfy/app/../var -R

WORKDIR /app

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

EXPOSE 80
EXPOSE 443

