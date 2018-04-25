#!/bin/bash -x

echo "mysql-server mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | sudo debconf-set-selections

sudo apt-get update
sudo apt-get install -y nginx \
  php7.0-cli \
  php7.0-cgi \
  php7.0-fpm \
  php7.0-zip \
  php7.0-mysql \
  php-curl \
  php-gd \
  php-mbstring \
  php-mcrypt \
  php-xml \
  php-xmlrpc \
  unzip \
  mysql-server

# mysql settings
sudo mysql -u root -proot -e "CREATE DATABASE web; GRANT ALL PRIVILEGES ON web.* TO 'webuser' IDENTIFIED BY 'password';"

# nginx settings
sudo mkdir -p /var/www/example.com/public_html

sudo tee /etc/nginx/sites-available/example.com << EOF
server {
    listen 80;
    listen [::]:80;

    server_name example.com;

    root   /var/www/example.com/public_html;
    index  index.html index.php;

    location / {
        index index.php index.html index.htm;
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/example.com/public_html\$fastcgi_script_name;
    }
}
EOF

sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled

# for osclass
wget https://static.osclass.org/download/osclass.3.7.0.zip -P ~
sudo unzip ~/osclass.3.7.0.zip -d /var/www/example.com/public_html
sudo chown -R www-data:www-data /var/www/example.com/
sudo chown -R www-data:www-data /var/www/example.com/public_html
sudo chmod a+w /var/www/example.com/public_html/oc-content/uploads/
sudo chmod a+w /var/www/example.com/public_html/oc-content/downloads/
sudo chmod a+w /var/www/example.com/public_html/oc-content/languages/
sudo chmod a+w /var/www/example.com/public_html/

# restart nginx and php
sudo systemctl restart php7.0-fpm nginx