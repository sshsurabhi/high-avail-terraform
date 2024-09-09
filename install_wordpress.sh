#!/bin/bash
# variables
DB_NAME="wordpress_db"            # Name of the database
DB_USER="datascientest-student"       # Database username
DB_PASSWORD="Datascientest@2024"      # Database password

WORDPRESS_DIR="/var/www/html"     # wordpress code directory

# Update the system
sudo yum update -y

# Install expect package
sudo yum install expect -y

# Install Apache HTTP server
sudo dnf install -y httpd wget php-fpm php-mysqli php-json php php-devel
sudo dnf install -y mariadb105-server
# Start Apache &  Enable Apache to start on boot
sudo systemctl start httpd && sudo systemctl enable httpd
sudo usermod -a -G apache ec2-user
# Create a PHP info page
sudo chown -R ec2-user:apache /var/www/html/
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;
echo "" > /var/www/html/phpinfo.php


# Install required PHP modules
sudo yum install php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip,imap} -y


# Start MariaDB & Enable MariaDB to start on boot

sudo systemctl enable --now mariadb

# Install
sudo yum install expect -y

# Secure the MariaDB installation
echo "Securing MariaDB installation..."
#expect -f <your_expect_script_here>  # Replace with your actual expect script or code
