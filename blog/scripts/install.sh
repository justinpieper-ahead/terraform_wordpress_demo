#!/bin/bash

apt-get update -y

apt-get install -y php7.2 php7.2-sql libapache2-mod-php7.2 php7.2-cli php7.2-gd php-mysql
apt-get install -y apache2 apache2-utils
apt-get install -y mysql-client mysql-server
apt-get install -y nfs-common unzip
apt-get install -y awscli
sleep 20 # Wait for efs record to propagate
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport efs.showturtles.com:/ /var/www/html

CONFIG="/var/www/html/wp-config.php"
if [ ! -f $CONFIG ]; then
    echo "Wordpress isn't configured.  Configuring."
    wget https://wordpress.org/latest.zip -O /var/www/html/wordpress.zip
    unzip /var/www/html/wordpress.zip -d /var/www/html/
    mv /var/www/html/wordpress/* /var/www/html/
    rmdir /var/www/html/wordpress
    rm /var/www/html/wordpress.zip
    aws s3 cp s3://jrpieper-personal-artifacts/wp-config.php /var/www/html/wp-config.php

    rm /var/www/index.html

fi

service apache2 restart
service apache2 reload
