#!/bin/sh

mkdir -p /usr/share/webapps/ && cd /usr/share/webapps/ && \
    wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz > /dev/null 2>&1 && \
    tar -xzvf phpMyAdmin-5.2.1-all-languages.tar.gz > /dev/null 2>&1 && \
    mv phpMyAdmin-5.2.1-all-languages phpmyadmin && \
    chmod -R 777 /usr/share/webapps/ && \
    ln -s /usr/share/webapps/phpmyadmin/ /var/www/localhost/htdocs/phpmyadmin

sed -i '/<Directory "\/var\/www\/localhost\/htdocs">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/httpd.conf

httpd

# reinstall mariadb if no more data
if [ ! -f /var/lib/mysql/ibdata1 ]; then 
    mariadb-install-db --user=mysql --ldata=/var/lib/mysql > /dev/null
fi;

tfile=`mktemp`
if [ ! -f "$tfile" ]; then
    return 1
fi

cat << EOF > $tfile
    CREATE DATABASE anikatsu;
    USE mysql;
    DELETE FROM user;
    FLUSH PRIVILEGES;
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
    UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
    FLUSH PRIVILEGES;
EOF

/usr/bin/mysqld --user=root --bootstrap --verbose=0 < $tfile
rm -f $tfile && \
fileCount=`ls -1 /home/*.sql 2>/dev/null | wc -l` && \
if [ $fileCount != 0 ]; then 
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" anikatsu < /home/*.sql
else
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" anikatsu < /var/www/localhost/htdocs/anikatsu.sql
    echo `mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e 'show databases'` >> /home/entry.log
    echo 'sql command to add anikatsu.sql run' >> /home/entry.log
fi 

/usr/bin/mysql -uroot -p"$MYSQL_ROOT_PASSWORD" anikatsu < /var/www/localhost/htdocs/anikatsu.sql

exec /usr/bin/mysqld --user=root --bind-address=127.0.0.1
