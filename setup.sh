#!/bin/bash

echo "Updating apt sources..."
sudo apt-get update -qq > /dev/null

echo "Installing and securing MariaDB..."

#SET MYSQL VARIABLE
USER=vagrant
DBROOTPASSWORD=mypassroot
DBNAME=wordpress
DBUSER=SoufiyanAK
DBPASSWORD=password
DBPREFIX=wnotp_

echo "mysql-server mysql-server/root_password password $DBROOTPASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBROOTPASSWORD" | debconf-set-selections
sudo apt-get install -qq mariadb-server > /dev/null
sudo mysql_install_db
# Emulate results of mysql_secure_installation, without using 'expect' to handle input
mysql --user=root --password=$DBROOTPASSWORD -e "UPDATE mysql.user SET Password=PASSWORD('$DBROOTPASSWORD') WHERE User='root'"
mysql --user=root --password=$DBROOTPASSWORD -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql --user=root --password=$DBROOTPASSWORD -e "DELETE FROM mysql.user WHERE User=''"
mysql --user=root --password=$DBROOTPASSWORD -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test_%'"
mysql --user=root --password=$DBROOTPASSWORD -e "FLUSH PRIVILEGES"

echo "Installing PHP and disabling path info default settings..."

sudo apt-get install -qq php5-fpm php5-mysql php5-gd libssh2-php > /dev/null
sudo apt-get install -qq php5 libapache2-mod-php5 php5-mcrypt > /dev/null
sudo cp /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini.orig
sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php5/fpm/php.ini
sudo service php5-fpm restart

echo "Installing APACHE and SSH..."

sudo apt-get install -qq apache2  > /dev/null
sudo apt-get install -qq openssh-server > /dev/null
sudo service php5-fpm restart

echo "Setup database for Wordpress..."

mysql --user=root --password=$DBROOTPASSWORD -e "CREATE DATABASE $DBNAME;"
mysql --user=root --password=$DBROOTPASSWORD -e "CREATE USER $DBUSER@localhost IDENTIFIED BY '$DBPASSWORD';"
mysql --user=root --password=$DBROOTPASSWORD -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER@localhost;"
mysql --user=root --password=$DBROOTPASSWORD -e "FLUSH PRIVILEGES;"

echo "Downloading and installing Wordpress and dependencies..."

# Download and extract Wordpress, and delete archive
wget http://wordpress.org/wordpress-4.9.1.tar.gz -q -P /tmp
tar xzfC /tmp/wordpress-4.9.1.tar.gz /tmp
rm /tmp/wordpress-4.9.1.tar.gz

echo "Setting up Wordpress configurations and file permissions..."

# Setup Wordpress config file with database info
cp /tmp/wordpress/wp-config-sample.php  /tmp/wordpress/wp-config.php
sed -i "s/database_name_here/$DBNAME/"  /tmp/wordpress/wp-config.php
sed -i "s/username_here/$DBUSER/"       /tmp/wordpress/wp-config.php
sed -i "s/password_here/$DBPASSWORD/"   /tmp/wordpress/wp-config.php
sed -i "s/wp_/$DBPREFIX/"               /tmp/wordpress/wp-config.php

# Add authentication salts from the Wordpress API
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s
' "g/$STRING/d" a "$SALT" . w | ed -s /tmp/wordpress/wp-config.php

# Move Wordpress to appropriate directory and set file permissions
SITEPATH=/var/www
sudo mkdir -p $SITEPATH/html
sudo rsync -aqP /tmp/wordpress/ $SITEPATH/html
sudo mkdir $SITEPATH/html/wp-content/uploads
sudo chown -R $USER:www-data $SITEPATH/*
rm -r /tmp/wordpress
rm /var/www/html/index.html

# Setup file and directory permissions on Wordpress
sudo find $SITEPATH/html -type d -exec chmod 0755 {} ;
sudo find $SITEPATH/html -type f -exec chmod 0644 {} ;
sudo chmod 0640 $SITEPATH/html/wp-config.php
sudo chmod -R 777 /var/www/html/
echo "Done!"
