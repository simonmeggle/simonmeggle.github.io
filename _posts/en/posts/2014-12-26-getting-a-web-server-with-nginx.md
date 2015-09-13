---
title:  Getting a web<br/> server with <em>Nginx</em>
redirect_from: /synchronize-calendars-and-contacts-with-owncloud/
---

A<em>pache</em> was once the ideal solution for creating a web server. Its great features induced a certain heaviness, and its popularity made him very attacked, and therefore frequently updated.

In recent years, *Nginx* has established itself as a high quality alternative: although comprehensive features, the software is characterized by great lightness, which allows to run on very modest configurations such as a Raspberry Pi.

 In line with the [previous article]({{site.base}}/installing-archlinux-on-raspberry-pi/), we'll see how to install a *Nginx* able to use PHP, on a Raspberry Pi which is running *Archlinux*. However, the procedure will remain very similar to another machine or other configuration[[it is essentially the commands `systemctl` and `pacman` which need to be adapted]].

## Installing *Nginx*

Installing *Nginx* is easily obtained with:

```bash
pacman -S nginx
```

It is then possible to start *Nginx* with:

```bash
systemctl start nginx
```

By opening the IP address[[or the domain name that points to your Raspberry Pi]] of your Raspberry Pi, you should see a page showing that *Nginx* is functional.

## Static website

We will start by creating a first site entirely static. The files will be located in `/srv/http/mysite`, which will be available at `mysite.tld`.

For this, we edit the *Nginx* configuration file:

```bash
nano /etc/nginx/nginx.conf
```

Before the latest ending curly bracket of the file, add the following lines for declaring our new website:

```nginx
server {
    listen 80;
    server_name mysite.tld;
    root /srv/http/mysite;
    index index.html;
}
```

The `listen` parameter specifies the listening port[[we generally chose port 80 for HTTP or 443 for HTTPS]], `server_name` allows to wanted URLs, `root` the file locations and `index` the file to be served by default.

We created this folder, and an `index.html` file with the right attributes:

```bash
mkdir -p /srv/http/mysite
nano /srv/http/index.html
```

Its configuration has been modified, we restart *Nginx* to take into account the changes:

```bash
systemctl restart nginx
```


## Dynamic website

Static websites, [that's goof]({{site.base}}/static-website-with-jekyll/), but being able to create dynamic sites is often helpful. This allows, for example, with a Raspberry Pi, to host web applications at home as an RSS reader or cloud. Examples are presented below.

### Installing PHP

To install PHP, we use the package `php-fpm` :

```bash
pacman -S php-fpm
```

The we activate it:

```bash
systemctl start php-fpm
```



### Creating a site with PHP

As before, we edit the *Nginx* configuration file:

```bash
nano /etc/nginx/nginx.conf
```

Before the latest ending curly bracket of the file, add the following lines for declaring how to handle PHP:

```nginx
server {
    listen 80;
    server_name mysite.tld;
    root /srv/http/mysite;
    index index.php;
    location ~ \.php$ {
       try_files $uri =404;
       fastcgi_split_path_info ^(.+\.php)(/.+)$;
       include fastcgi.conf;
       fastcgi_index index.php;
       fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
    }
}
```

Again, we restart *Nginx*:

```bash
systemctl restart nginx
```

### Installer *sqlite*

A growing number of web applications use `sqlite` as a database. If you need it, install the package `php-sqlite` :

```bash
pacman -S php-sqlite
```

Then tells PHP to use it by adding at the end of file `/etc/php/php.ini` :

```bash
extension=pdo_sqlite.so
```

Then we restart PHP:

```bash
systemctl restart php-fpm
```

### Installing *MySQL*

If you want to use *MySQL*, install the `mariadb` package, start `mysqld` then use the installation script:
```bash
pacman -S mariadb
systemctl start mysqld
mysql_secure_installation
```

As before, we then tells PHP to use by adding at the end of file `/etc/php/php.ini` :

```bash
extension=mysql.so
```



## Examples

### Getting an RSS reader *Miniflux*

*Miniflux* is a web application for reading RSS feeds that I particularly appreciated for its simplicity and minimalist design. It is the replacement for *Google Reader* I've searched for a long time.

As previously stated, creating a dynamic site for the folder `/srv/http/miniflux/` taking care to install *sqlite*, needed by *Miniflux*.

Installation is simple: download *Miniflux*, extract it, and give write access to the folder `data/`.

```
cd /srv/http/
wget http://miniflux.net/miniflux-latest.zip
unzip miniflux-latest.zip
rm miniflux-latest.zip
cd miniflux
chmod 777 data/
```

Then, to enable monitoring RSS feeds every hour, create a `cron` task with:

```bash
crontab -e
```

Then enter therein:

```bash
0 */1 * * *  cd /srv/http/miniflux && php cronjob.php >/dev/null 2>&1
```


### Getting a personnal cloud with *OwnCloud*

Synchronize calendars, contacts and files between different devices - computers, tablets, phones - is very common today. Because these data can be very personal, installing a web application like *OwnCloud* on its Raspberry Pi.

Again, create a dynamic site for `/srv/http/owncloud/`. Then, we download *OwnCloud*:

```bash
mkdir -p /srv/http/owncloud
wget http://download.owncloud.org/community/owncloud-7.0.4.tar.bz2
tar xvf owncloud-7.0.4.tar.bz2
mv owncloud/ /srv/http/
chown -R www-data:www-data /srv/http
rm -rf owncloud owncloud-7.0.4.tar.bz2
```

We then add a `cron` task that will automate the update by running:

```bat
crontab -e
```

Then enter therein:

```r
*/15  *  *  *  * php -f /srv/http/owncloud/cron.php
```

From our local network, we can access the web interface OwnCloud by going to the address of our Raspberry Pi (the external IP or the domain name).

In *Applications* uncheck all applications you won’t use, in order to make OwnCloud more fluid. I only keep “Calendar” and “Contacts”.

In *Administration*, uncheck the share permissions that are not useful, and select `cron` as the update method.

You can start creating address books and calendars from the web interface. It provides links `CardDAV` and `CalDAV` which can then be entered, along with your username and password, on your computers and devices.
