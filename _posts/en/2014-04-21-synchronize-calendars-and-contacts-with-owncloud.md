---
title: Calendars and contacts with <em>OwnCloud</em>
name:  owncloud
---

Synchronize calendars, contacts and files between different devices - computers, tablets, phones - is very common today. Despite these data can be very personal, sometimes sensitive, most people use the tools provided by Google, Apple or Microsoft.

However, some powerful open source solutions exist. Here we will show how to use [_OwnCloud_](http://owncloud.org/) on a [Raspberry Pi](http://www.raspberrypi.org/), a small server under $40, to synchronize our calendars and contacts. If you already have a functional server, you can jump to the last part.

## Installation and configuration of the Raspberry Pi
This tutorial assumes that you have a Raspberry Pi Type B, connected to your network, an SD card with at least 2GB, and a µUSB power cable. We will use here the distribution [Raspbian](http://www.raspbian.org/) but OwnCloud should be available for most distributions.

We don't aim to compete with the many tutorials that help install Raspbian, but to offer an optimized configuration for OwnCloud.

### Installing Raspbian

Let's start by [getting Raspbian](http://www.raspberrypi.org/downloads/), and insert the SD card on your computer. In Mac OS or Linux, run the following command:


{% highlight bash %}
diskutil list
{% endhighlight %}

After having located your SD card identifier (`/dev/disk2` in the example below), we write Raspbian on it. Beware, all of its contents will be erased:

{% highlight bash %}
diskutil unmountDisk /dev/disk2
sudo dd if=raspbian.img of=/dev/disk2 bs=1m
sudo diskutil eject /dev/rdisk2
{% endhighlight %}

You can eject the card, insert it into your Raspberry Pi connected to the network and turn it on.


We will connect via SSH to our Raspberry Pi in order to configure it. We need to know its IP address: run `arp -a` and identify the Raspberry Pi IP. Once you know it (`192.168.1.1` in the following examples), you can use SSH: `ssh pi@192.168.1.1`.

After accepting the SSH security certificate warning, you can connect by entering the default password `raspberry`.

### Updating and configuring Raspbian

Due to several partnerships of the Raspberry Pi Foundation, the image of Raspbian now contains three packets `oracle-jdk-java7`, `wolfram-engine` and `scratch` which account for 635 MB. If you don't need them, we can remove them:

    sudo apt-get purge wolfram-engine oracle-java7-jdk scratch

We update the entire system:

    sudo apt-get update && sudo apt-get dist-upgrade

Then, we finalize the installation with the `raspi-config` utility. 
Several options interests us:

* _1. Expand Filesystem_ in order to use the entire SD card;
* _2. Change User Password_ in order to change the default password;
* _4. Internationalisation Options_ in order to choose the locales: use `en_US.UTF-8` for OwnCloud other langages if needed, then select the default one; you can also select the time zone;
* _7. Overclock_: choose 4 _Medium_.
* _8. Advanced Options_ then _A3. Split Memory_  where you choose 16 MB, in order to free as memory as possible.

We reboot our Raspberry Pi.

## Installing and configuring the `nginx` server

This part is not necessary if you already use a server and that you have already installed `apache` or `nginx`. It shows how to install `nginx` and how to optimize it for a Raspberry Pi

### Preparation 

We begin by installing the necessary dependencies, including the lightweight `nginx` server and PHP5:

{% highlight sh %}
sudo apt-get update && sudo apt-get dist-upgrade
sudo apt-get install nginx openssl ssl-cert php5-cli \
             php5-sqlite php5-gd php5-curl php5-common \
             php5-cgi sqlite3 php-pear php-apc curl \
             libapr1 libtool curl libcurl4-openssl-dev \
             php-xml-parser php5 php5-dev php5-gd \
             php5-fpm memcached php5-memcache ntp varnish
{% endhighlight %}

Then, we create an user for the  `nginx` server:

{% highlight bat %}
sudo groupadd www-data
sudo usermod -a -G www-data www-data
{% endhighlight %}

We also create SSL keys in order to secure the future connexion with the calendars and contacts:

{% highlight bat %}
sudo openssl req $@ -new -x509 -days 365 -nodes -out /etc/nginx/cert.pem -keyout /etc/nginx/cert.key
sudo chmod 600 /etc/nginx/cert.pem
sudo chmod 600 /etc/nginx/cert.key
{% endhighlight %}


## Configuring `nginx`

Delete the default configuration file, and create a new one:

{% highlight bat %}
sudo rm /etc/nginx/sites-available/default
sudo unlink /etc/nginx/sites-enabled/default
sudo nano /etc/nginx/sites-available/owncloud
{% endhighlight %}

Put the following configuration (replace `your-ip` with your _extern_ IP address, which can be known with `dig +short myip.opendns.com @resolver1.opendns.com`):

{% highlight nginx %}
upstream php-handler {
        server 127.0.0.1:9000;
}
server {
    listen 80;
    server_name your-ip;
    return 301 https://$server_name$request_uri;
}
server {
    listen 443 ssl;
    server_name your-ip;
    ssl_certificate /etc/nginx/cert.pem;
    ssl_certificate_key /etc/nginx/cert.key;
    root /var/www/owncloud;
    client_max_body_size 1000M;
    fastcgi_buffers 64 4K;
    rewrite ^/caldav(.*)$ /remote.php/caldav$1 redirect;
    rewrite ^/carddav(.*)$ /remote.php/carddav$1 redirect;
    rewrite ^/webdav(.*)$ /remote.php/webdav$1 redirect;
    index index.php;
    error_page 403 /core/templates/403.php;
    error_page 404 /core/templates/404.php;
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    location ~ ^/(data|config|\.ht|db_structure\.xml|README) {
      deny all;
    }
    location / {
        rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
        rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json last;
        rewrite ^/.well-known/carddav /remote.php/carddav/ redirect;
        rewrite ^/.well-known/caldav /remote.php/caldav/ redirect;
        rewrite ^(/core/doc/[^\/]+/)$ $1/index.html;
        try_files $uri $uri/ index.php;
    }
    location ~ ^(.+?\.php)(/.*)?$ {
        try_files $1 = 404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$1;
        fastcgi_param PATH_INFO $2;
        fastcgi_param HTTPS on;
        fastcgi_pass 127.0.0.1:9000;
    }
        location @webdav {
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS on;
        include fastcgi_params;
    }
    location ~* ^.+\.(jpg|jpeg|gif|bmp|ico|png|css|js|swf)$ {
        expires 30d;
        access_log off;
    }
}
{% endhighlight %}

We activate this configuration: 

{% highlight bat %}
cd /etc/nginx/sites-enabled
sudo ln -s ../sites-available/owncloud
{% endhighlight %}

### Configuring PHP
We need to configure PHP in order to use OwnCloud:

{% highlight bat %}
sudo nano /etc/php5/fpm/php.ini
{% endhighlight %}

In this file, change or add the following parameters:

{% highlight apache %}
upload_max_filesize = 1000M
post_max_size = 1000M
upload_tmp_dir = /srv/http/owncloud/data
extension = apc.so
apc.enabled = 1
apc.include_once_override = 0
apc.shm_size = 256
{% endhighlight %}

We also modify the listening parameter, and create the following folder:

{% highlight bat %}
sudo sed /etc/php5/fpm/pool.d/www.conf -i -e "s|listen = /var/run/php5-fpm.sock|listen = 127.0.0.1:9000|g"
sudo mkdir -p /srv/http/owncloud/data
sudo chown www-data:www-data /srv/http/owncloud/data
{% endhighlight %}

Then, we change `100` into `512` in the following file:

{% highlight bat %}
sudo nano /etc/dphys-swapfile
{% endhighlight %}

We need to apply the changes:

{% highlight bat %}
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
{% endhighlight %}

Finally, we restart PHP and the `nginx` server:

{% highlight bat %}
sudo /etc/init.d/php5-fpm restart
sudo /etc/init.d/nginx restart
{% endhighlight %}


### Port forwarding
In order to access the web interface OwnCloud (port 80) and synchronize contacts and calendars (443), it is necessary to route these two ports: users will access the IP address outside of your network, and your router or your box must transfer this information to your Raspberry Pi.

The procedure depends entirely on your router or box: in their administration interface, specify that ports 80 and 443 have to be redirected to the IP address of the Raspberry Pi, after stating the router to assign to it a fixed IP address.

### Domain name

This is optional, but it is also possible to use a domain name rather than an IP address. After completing the steps above, go to your registar, create a field redirecting your domain name (or subdomain) to the external IP address of your network. Then, in `/etc/nginx/sites-available/owncloud`, replace both `server_name` by the domain name and restart `nginx`.


## Installing and configuring OwnCloud

### Installation
It remains only to install OwnCloud:

{% highlight bat %}
sudo mkdir -p /var/www/owncloud
sudo wget http://download.owncloud.org/community/owncloud-6.0.2.tar.bz2
sudo tar xvf owncloud-6.0.2.tar.bz2
sudo mv owncloud/ /var/www/
sudo chown -R www-data:www-data /var/www
sudo rm -rf owncloud owncloud-6.0.2.tar.bz2
{% endhighlight %}

We then add a `cron` task that will automate the update by running:

{% highlight bat %}
sudo crontab -e
{% endhighlight %}

Provide the following rule:

{% highlight r %}
*/15  *  *  *  * php -f /var/www/owncloud/cron.php
{% endhighlight %}


### Configuration
From our local network, we can access the web interface OwnCloud by going to the address of our Raspberry Pi (the external IP or the domain name). The warning security is normal: our certificate is not verified by an independent authority.

Choose a username and a password. The following error message is normal.

In _Applications_ uncheck all applications you won't use, in order to make OwnCloud more fluid. I only keep "Calendar" and "Contacts".

In _Administration_, uncheck the share permissions that are not useful, and select "cron" as the update method.

## That's all folks!
You can start creating address books and calendars from the web interface. It provides links `CardDAV` and `CalDAV` which can then be entered, along with your username and password, on your computers and devices.
