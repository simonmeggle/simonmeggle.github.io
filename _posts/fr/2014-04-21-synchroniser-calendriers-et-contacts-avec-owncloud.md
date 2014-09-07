---
title: Calendriers et contacts <br/> avec <em>OwnCloud</em>
---

Synchroniser ses calendriers, contacts et différents fichiers entre différents périphériques -- ordinateurs, tablettes, téléphones -- est aujourd'hui très courant. Malgré le caractère très personnel, voire sensible, de ces données, la grande majorité utilise les outils proposés par Google, Apple ou Microsoft.

Pourtant, des solutions libres très performantes existent. Nous allons ici montrer comment utiliser [_OwnCloud_](http://owncloud.org/) sur un [Raspberry Pi](http://www.raspberrypi.org/), un petit serveur de moins de 35 €, pour synchroniser nos calendriers et nos contacts. Si vous possédez déjà un serveur fonctionnel, vous pouvez directement passer à la dernière partie.


## Installation et paramétrage du Raspberry Pi 
Ce tutoriel suppose que vous avez un Raspberry Pi, modèle B, branché sur votre réseau, une carte SD d'au moins 2 Go, et un câble d'alimentation µUSB. Nous allons utiliser ici la distribution [Raspbian](http://www.raspbian.org/), mais OwnCloud devrait être disponible pour la plupart des distributions. 

L'objectif ici n'est pas de concurrencer les très nombreux tutoriels qui aident à installer Raspbian, mais de proposer une configuration optimisée pour OwnCloud.

### Installation de Raspbian

Commençons par [récupérer Raspbian](http://www.raspberrypi.org/downloads/), et insérons la carte SD sur votre ordinateur. Sous Mac OS ou Linux, lancez dans le terminal la commande suivante :

```bash
diskutil list
```

Après avoir repéré l'identifiant de votre carte SD (`/dev/disk2` dans l'exemple qui suit), on écrit Raspbian dessus. Attention, l'intégralité de son contenu sera effacé :

```bash
diskutil unmountDisk /dev/disk2
sudo dd if=raspbian.img of=/dev/disk2 bs=1m
sudo diskutil eject /dev/rdisk2
```

Vous pouvez éjecter la carte, l'insérer dans votre Raspberry Pi branché sur le réseau, et allumer ce dernier.


Nous allons nous connecter en SSH à notre Raspberry Pi pour le configurer. Il nous faut connaître son adresse IP : exécutez pour cela `arp -a` dans le terminal et identifiez l'adresse IP du Raspberry Pi. Une fois celle-ci connue (nous prendrons `192.168.1.1` dans la suite), on peut se connecter en SSH : `ssh pi@192.168.1.1`.

Après avoir accepté la mise en garde de sécurité sur le certificat SSH, vous pouvez vous connecter en entrant le mot de passe par défaut `raspberry`. 

### Mise à jour et configuration de Raspbian

À la suite de plusieurs partenariats passés par la fondation Raspberry Pi, l'image de Raspbian contient aujourd'hui trois paquets `oracle-java7-jdk`, `wolfram-engine` et `scratch` qui représentent à eux seuls 635 Mo. S'ils ne sont d'aucune utilité, nous pouvons les supprimer :

```bash
sudo apt-get purge wolfram-engine oracle-java7-jdk scratch
```

Nous mettons ensuite l'intégralité du système à jour :

```bash
sudo apt-get update && sudo apt-get dist-upgrade
```

Enfin, nous finalisons l'installation à l'aide de l'utilitaire `raspi-config`. Plusieurs options nous intéressent.

* _1. Expand Filesystem_ pour occuper l'intégralité de la carte SD ;
* _2. Change User Password_ pour changer le mot de passe par défaut de l'utilisateur `pi` ;
* _4. Internationalisation Options_ permet de choisir les locales : installer `en_US.UTF-8` dans tous les cas pour OwnCloud et d'autres langues si besoin (`fr_FR.UTF-8` pour le français), puis choisir la langue par défaut ; il est également possible de choisir son fuseau horaire ;
* _7. Overclock_ : choisir la valeur 4 _Medium_.
* _8. Advanced Options_ puis _A3. Split Memory_  où l'on choisit de ne donner que  16 Mo à la puce graphique, afin de libérer le maximum de mémoire.

On redémarre alors notre Raspberry Pi.


## Installation et configuration du serveur `nginx`

Cette partie est inutile si vous utilisez un serveur et que vous y avez déjà installé `apache` ou `nginx`. Elle montre comment installer `nginx` et le paramétrer de façon assez optimisée pour qu'Owncloud soit suffisamment rapide sur Raspberry Pi.

### Préparation 

Commençons par installer les dépendances nécessaires, notamment le serveur léger `nginx` et PHP5 :

```sh
sudo apt-get update && sudo apt-get dist-upgrade
sudo apt-get install nginx openssl ssl-cert php5-cli \
             php5-sqlite php5-gd php5-curl php5-common \
             php5-cgi sqlite3 php-pear php-apc curl \
             libapr1 libtool curl libcurl4-openssl-dev \
             php-xml-parser php5 php5-dev php5-gd \
             php5-fpm memcached php5-memcache ntp varnish
```

Nous créons ensuite un utilisateur pour le serveur `nginx` :

```bat
sudo groupadd www-data
sudo usermod -a -G www-data www-data
```

Nous créons également des clefs SSL pour sécuriser les connexions avec nos calendriers et nos carnets d'adresse :

```bat
sudo openssl req $@ -new -x509 -days 365 -nodes -out /etc/nginx/cert.pem -keyout /etc/nginx/cert.key
sudo chmod 600 /etc/nginx/cert.pem
sudo chmod 600 /etc/nginx/cert.key
```


## Configuration de `nginx`

Supprimons le fichier de configuration par défaut, et créons-en un nouveau :

```bat
sudo rm /etc/nginx/sites-available/default
sudo unlink /etc/nginx/sites-enabled/default
sudo nano /etc/nginx/sites-available/owncloud
```

Nous y installons la configuration suivante, qui permettra de faire fonctionner _OwnCloud_ en optimisant la vitesse d'exécution de PHP (remplacez `votre-ip`) par l'adresse IP _externe_, que vous pouvez connaître à l'aide de `dig +short myip.opendns.com @resolver1.opendns.com`) :

```nginx
upstream php-handler {
        server 127.0.0.1:9000;
}
server {
    listen 80;
    server_name votre-ip;
    return 301 https://$server_name$request_uri;
}
server {
    listen 443 ssl;
    server_name votre-ip;
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
```

On active alors cette configuration :

```bat
cd /etc/nginx/sites-enabled
sudo ln -s ../sites-available/owncloud
```

### Configuration de PHP
Pour optimiser OwnCloud, nous modifions la configuration de PHP :

```bat
sudo nano /etc/php5/fpm/php.ini
```

Dans ce fichier, modifiez ou ajouter les paramètres suivants :

```apache
upload_max_filesize = 1000M
post_max_size = 1000M
upload_tmp_dir = /srv/http/owncloud/data
extension = apc.so
apc.enabled = 1
apc.include_once_override = 0
apc.shm_size = 256
```

Nous modifions également le paramètre d'écoute et créons le dossier avec les droits :

```bat
sudo sed /etc/php5/fpm/pool.d/www.conf -i -e "s|listen = /var/run/php5-fpm.sock|listen = 127.0.0.1:9000|g"
sudo mkdir -p /srv/http/owncloud/data
sudo chown www-data:www-data /srv/http/owncloud/data
```

Nous modifions enfin `100` en `512` dans le fichier suivant :

```bat
sudo nano /etc/dphys-swapfile
```

Nous validons la modification :

```bat
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```
 

On redémarre alors le serveur web et PHP :

```bat
sudo /etc/init.d/php5-fpm restart
sudo /etc/init.d/nginx restart
```


### Routage des ports
Afin de pouvoir accéder à l'interface web d'OwnCloud (port 80) et synchroniser les contacts et les calendriers (port 443), il est nécessaire de router ces deux ports : les utilisateurs extérieurs à votre réseau vont accéder à l'adresse IP externe de votre réseau, et votre routeur ou votre box doivent transférer ces informations à votre Raspberry Pi.

La marche à suivre dépend entièrement de votre routeur ou de votre box : dans leur interface d'administration, indiquez que les ports 80 et 443 doivent rediriger vers l'adresse IP du Raspberry Pi, après avoir indiqué au routeur d'attribuer à ce dernier une IP fixe.

### Nom de domaine

C'est facultatif, mais il est également possible d'utiliser un nom de domaine plutôt qu'une adresse IP externe. Après avoir accompli les étapes précédentes, rendez-vous chez votre registar. Créez un champ `A` redirigeant de votre nom de domaine (ou un sous-domaine) vers l'adresse IP externe de votre réseau.

Enfin, dans `/etc/nginx/sites-available/owncloud`, remplacez les deux paramètres `server_name` par ce nom de domaine et redémarrez `nginx`.


## Installation et configuration d'OwnCloud

### Installation

Il ne nous reste qu'à installer OwnCloud :

```bat
sudo mkdir -p /var/www/owncloud
sudo wget http://download.owncloud.org/community/owncloud-6.0.2.tar.bz2
sudo tar xvf owncloud-6.0.2.tar.bz2
sudo mv owncloud/ /var/www/
sudo chown -R www-data:www-data /var/www
sudo rm -rf owncloud owncloud-6.0.2.tar.bz2
```

Nous ajoutons ensuite une tâche `cron` qui va automatiser la mise à jour en exécutant :

```bat
sudo crontab -e
```

Dans le fichier ouvert, entrez :

```r
*/15  *  *  *  * php -f /var/www/owncloud/cron.php
```


### Configuration
Depuis notre réseau local, nous pouvons accéder à l'interface web d'OwnCloud en allant sur l'adresse de notre Raspberry Pi (l'IP externe ou le nom de domaine). L'avertissement de sécurité du navigateur est normal : notre certificat n'est pas vérifié par une autorité indépendante. 

Choisissons un nom d'utilisateur et un mot de passe. Le message d'erreur qui suit est normal.

Dans _Applications_, décochez toutes les applications qui ne seront pas utilisées pour rendre OwnCloud plus fluide. Je ne conserve pour ma part que "Calendrier" et "Contacts". 

Dans _Administration_, décochez les autorisations de partage qui ne sont pas utiles, et sélectionnez "cron" dans le mode de mise à jour.


## C'est prêt !
Vous pouvez commencer à créer des carnets d'adresse et des calendriers depuis l'interface web. Celle-ci fournit des liens `cardDav` et `calDav` qui peuvent ensuite être renseignés, accompagnés de votre nom d'utilisateur et de votre mot de passe OwnCloud, sur vos différents ordinateurs et périphériques.
