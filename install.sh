#!/bin/bash -x

osclass_version=3.7.4
domain_name=example.com
osclass_root="/var/www/${domain_name}/public_html"

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
sudo mysql -u root -proot -e "CREATE DATABASE osclass; GRANT ALL PRIVILEGES ON osclass.* TO 'osclass' IDENTIFIED BY 'osclass';"

# nginx settings
sudo mkdir -p ${osclass_root}

sudo tee /etc/nginx/sites-available/${domain_name} << EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${domain_name};

    root   ${osclass_root};
    index  index.html index.php;

    location / {
        index index.php index.html index.htm;
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        fastcgi_param SCRIPT_FILENAME ${osclass_root}\$fastcgi_script_name;
    }
}
EOF

sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/${domain_name} /etc/nginx/sites-enabled

# for osclass
wget https://static.osclass.org/download/osclass.${osclass_version}.zip -P ~
sudo unzip ~/osclass.${osclass_version}.zip -d ${osclass_root}
sudo chown -R www-data:www-data ${osclass_root}
sudo chmod a+w ${osclass_root}/oc-content/uploads/ \
${osclass_root}/oc-content/downloads/ \
${osclass_root}/oc-content/languages/ \
${osclass_root}

# restart nginx and php
sudo systemctl restart php7.0-fpm nginx