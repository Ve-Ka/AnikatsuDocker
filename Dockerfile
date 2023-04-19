FROM alpine:latest
ENV TIMEZONE Asia/Kuala_Lumpur
RUN apk update && apk add \
    mariadb \
    mariadb-client \
    apache2 \ 
    apache2-utils \
    wget \
    tzdata \
    php81-apache2 \
    php81-cli \
    php81-pdo_mysql \
    php81-mysqli \
    php81-session \
    git

WORKDIR /var/www/localhost/htdocs/
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mkdir -p /run/apache2 && chown -R apache:apache /run/apache2 && chown -R apache:apache /var/www/localhost/htdocs/ && \
    sed -i 's#\#LoadModule rewrite_module modules\/mod_rewrite.so#LoadModule rewrite_module modules\/mod_rewrite.so#' /etc/apache2/httpd.conf && \
    sed -i 's#ServerName www.example.com:80#\nServerName localhost:80#' /etc/apache2/httpd.conf && \
    sed -i 's/skip-networking/\#skip-networking/i' /etc/my.cnf.d/mariadb-server.cnf && \
    sed -i '/mariadb\]/a log_error = \/var\/lib\/mysql\/error.log' /etc/my.cnf.d/mariadb-server.cnf && \
    sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/my.cnf.d/mariadb-server.cnf && \
    sed -i '/mariadb\]/a skip-external-locking' /etc/my.cnf.d/mariadb-server.cnf && \
    sed -i '/mariadb\]/a general_log = ON' /etc/my.cnf.d/mariadb-server.cnf && \
    sed -i '/mariadb\]/a general_log_file = \/var\/lib\/mysql\/query.log' /etc/my.cnf.d/mariadb-server.cnf
RUN sed -i 's#display_errors = Off#display_errors = On#' /etc/php81/php.ini && \
    sed -i 's#session.cookie_httponly =#session.cookie_httponly = true#' /etc/php81/php.ini && \
    sed -i 's#error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT#error_reporting = E_ALL#' /etc/php81/php.ini
COPY entry.sh /entry.sh
RUN chmod u+x /entry.sh
RUN rm -rf *
RUN git clone https://github.com/shashankktiwariii/anikatsu.git .
RUN rm _config.php
RUN ln -s /home/_config.php _config.php
EXPOSE 80
ENTRYPOINT ["/entry.sh"]
