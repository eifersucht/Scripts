#!/bin/bash

echo
echo "Bash Script for websites backup (Data & Database) data fix (Security and premissions) and Amazon S3 files put"
read -p "Backup all the /var/www folder data? (Y/n)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    #Get all domains in /var/www
    cd /var/www
    alldomains=(*)
    cd
    for domain in "${alldomains[@]}"; do
        ee site info $domain >> /path/to/backups/folder/WebsiteInfo$todayDate.txt
        echo "Making tar.gz file of domain file in /var/www/$domain"
        todayDate=$(date +'%m-%d-%Y')
        mkdir /path/to/backups/folder/$todayDate
        echo "Creating $domain files copy with name $domain$todayDate.tar.gz in /path/to/backups/folder/$todayDate"
        tar -zcvf /path/to/backups/folder/$todayDate/$domain$todayDate.tar.gz /var/www/$domain/
        echo "Created backup file for $domain with name $domain$todayDate.tar.gz in /path/to/backups/folder/$todayDate"
        echo "Applying fixer to files in /var/www/$domain folder"
        path="/var/www/$domain/htdocs/"
        file=$path../wp-config.php
        if [ -e "$file" ]; then
            echo "Checking and rewriting file ownership to www-data and group www-data"
            chown www-data:www-data -R $path
            echo "Fixing folders permissions for wordpress"
            find . -type d -exec chmod 755 {} \;
            echo "Fixing files permissions for wordpress"
            find . -type f -exec chmod 644 {} \;
            echo "Securing wp-config"
            chmod 444  $path../wp-config.php
            echo "Securing nginx.conf in $path (WP Security plugin file)"
            nginxfile="nginx.conf"
            chmod 444 $path$nginxfile
            echo "All actions done for $domain"
            echo "============================"
        else
            echo "The website $domain is not wordpress no extra configuraion needed"
            echo "============================"
        fi
    done
    read -p "Put backup folder to Amazon S3?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #Command to put files into Amazon S3
        echo "Making all website databases copy"
        mysqldump --user=**** --password=***** -A > /path/to/backups/folder/$todayDate/ddbbserverName$todayDate.sql
        echo "Compressing database"
        tar -zcvf /path/to/backups/folder/$todayDate/ddbbserverName$todayDate.sql.tar.gz /path/to/backups/folder/$todayDate/ddbbserverName$todayDate.sql
        echo "Deleting uncompressed database file"
        rm /path/to/backups/folder/$todayDate/ddbbserverName$todayDate.sql
    fi   
    read -p "Put backup folder to Amazon S3?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        #Command to put files into Amazon S3
        s3cmd put --recursive /path/to/backups/folder/$todayDate s3://droplet-name/droplet-folder/
    fi
fi