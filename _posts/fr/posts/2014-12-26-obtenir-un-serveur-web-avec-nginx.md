---
title:  Obtenir un serveur<br/> web avec <em>Nginx</em>
redirect_from: /synchroniser-calendriers-et-contacts-avec-owncloud/
---

A<em>pache</em> était il y a peu la solution incontournable pour créer un serveur web. Ses très nombreuses fonctionnalités induisaient une lourdeur certaine, et son omniprésence le rendait très attaqué, et donc fréquemment mis à jour.

Depuis quelques années, *Nginx* s'est affirmé comme une alternative de grande qualité : bien que très complet du point de vue des fonctionnalités, le logiciel se caractérise par une très grande légereté, qui le permet de tourner sur des configurations très modestes, comme (à tout hasard) un Raspberry Pi.

Dans la ligne de [l'article précédent]({{site.base}}/installer-archlinux-sur-raspberry-pi/), nous allons voir comment installer un *Nginx* capable d'utiliser PHP sur un Raspberry Pi sur lequel est installé *Archlinux*. Néanmoins, la procédure restera très similaire sur une autre machine ou une autre configuration[[ce sont essentiellement les commandes `pacman` et `systemctl` qui devront être adaptées]].

## Installer *Nginx*

L'installation de *Nginx* s'obtient aisément avec :

```bash
pacman -S nginx
```

Il est alors possible de démarrer manuellement *Nginx* avec :

```bash
systemctl start nginx
```

En ouvrant l'adresse IP[[ou le nom de domaine qui pointe vers votre Raspberry Pi]] de votre Raspberry Pi, vous devriez alors voir apparaître une page attestant que *Nginx* est bien fonctionnel.

## Site statique

Nous allons commencer par créer un premier site, entièrement statique. Les fichiers seront situés dans `/srv/http/monsite`, qui sera disponible à l'URL `monsite.tld`.

Pour cela, nous éditons le fichier de configuration de *Nginx* :

```bash
nano /etc/nginx/nginx.conf
```

Avant la toute dernière accolade du fichier, ajoutons les lignes suivantes qui permettent de déclarer notre nouvel site :

```nginx
server {
    listen 80;
    server_name monsite.tld;
    root /srv/http/monsite;
    index index.html;
}
```

Le paramètre `listen` indique le port d'écoute[[on choisit généralement le port 80 pour du HTTP classique, ou 443 pour du HTTPS]], `server_name` permet de déclarer le(s) chemin(s) d'accès au site, `root` les emplacements des fichiers et `index` le fichier à servir par défaut.

On créé le dossier en question, ainsi qu'un fichier index.html, et on lui donne les bons attributs :

```bash
mkdir -p /srv/http/monsite
nano /srv/http/index.html
```

Sa configuration ayant été modifiée, on relance *Nginx* pour prendre en compte les changements :

```bash
systemctl restart nginx
```


## Site dynamique

Les sites statiques, [c'est bien]({{site.base}}/site-statique-avec-jekyll/), mais pouvoir créer des sites dynamiques est souvent bien utile. Cela permet par exemple, depuis un *Raspberry Pi*, de pouvoir héberger chez soi des applications web comme un lecteur de flux RSS ou un *cloud*. Des exemples sont présentés ci-dessous.

### Installation de PHP

Pour installer PHP, nous utilisons le paquet `php-fpm` :

```bash
pacman -S php-fpm
```

On active alors celui-ci :

```bash
systemctl start php-fpm
```



### Création d'un site avec PHP

Comme précedemment, nous éditons le fichier de configuration de *Nginx* :

```bash
nano /etc/nginx/nginx.conf
```

Avant la toute dernière accolade du fichier, ajoutons les lignes suivantes, qui comprennent cette fois-ci une nouvelle partie permettant de déclarer la façon de traiter les fichiers PHP :

```nginx
server {
    listen 80;
    server_name monsite.tld;
    root /srv/http/monsite;
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

On relance à nouveau *Nginx* :

```bash
systemctl restart nginx
```

### Installer *sqlite*

Un nombre croissant d'applications web utilisent `sqlite` en guise de base de données. S'il vous est nécessaire, commencez par installer le paquet `php-sqlite` :

```bash
pacman -S php-sqlite
```

On indique alors à PHP de l'utiliser en ajoutant, à la fin du fichier `/etc/php/php.ini` :

```bash
extension=pdo_sqlite.so
```

On redémarre alors PHP :

```bash
systemctl restart php-fpm
```

### Installer *MySQL*

Pour utiliser *MySQL*, on installe le paquet `mariadb`, qu'on active, puis on lance le script d'installation :

```bash
pacman -S mariadb
systemctl start mysqld
mysql_secure_installation
```

Comme précédemment, on indique alors à PHP de l'utiliser en ajoutant, à la fin du fichier `/etc/php/php.ini` :

```bash
extension=mysql.so
```



## Exemples

### Obtenir un lecteur de flux RSS avec *Miniflux*

*Miniflux* est une application web de lecture de flux RSS que j'apprécie particulièrement pour sa simplicité et son design minimaliste. Il constitue le remplaçant à *Google Reader* que j'ai recherché pendant longtemps.

Comme indiqué précédemment, créons un site dynamique pour le dossier `/srv/http/miniflux/` en prenant garde d'installer *sqlite* que *Miniflux* nécessite.

L'installation se fait alors simplement : on télécharge *Miniflux*, qu'on décompresse, et on donne les droits de lecture au dossier `data/`.

```
cd /srv/http/
wget http://miniflux.net/miniflux-latest.zip
unzip miniflux-latest.zip
rm miniflux-latest.zip
cd miniflux
chmod 777 data/
```

Puis, pour activer la surveillance des flux RSS toutes les heures, on créée une tâche `cron` avec la commande :

```bash
crontab -e
```

On y inscrit alors :

```bash
0 */1 * * *  cd /srv/http/miniflux && php cronjob.php >/dev/null 2>&1
```


### Obtenir un *cloud* personnel avec *OwnCloud*

Synchroniser ses calendriers, contacts et différents fichiers entre différents périphériques -- ordinateurs, tablettes, téléphones -- est aujourd'hui très courant. Du fait du caractère très personnel, voire sensible, de ces données, il peut être intéressant d'installer un outil comme *OwnCloud* sur son Raspberry Pi.

À nouveau, créons un site dynamique pour le dossier `/srv/http/owncloud/`. Nous y téléchargeons alors *OwnCloud* :

```bash
mkdir -p /srv/http/owncloud
wget http://download.owncloud.org/community/owncloud-7.0.4.tar.bz2
tar xvf owncloud-7.0.4.tar.bz2
mv owncloud/ /srv/http/
chown -R www-data:www-data /srv/http
rm -rf owncloud owncloud-7.0.4.tar.bz2
```

Nous ajoutons ensuite une tâche `cron` qui va automatiser la mise à jour en exécutant :

```bat
crontab -e
```

On y inscrit alors :

```r
*/15  *  *  *  * php -f /srv/http/owncloud/cron.php
```


Depuis notre réseau local, nous pouvons accéder à l'interface web d'OwnCloud en allant sur l'adresse de notre Raspberry Pi (l'IP externe ou le nom de domaine).

Dans _Applications_, décochez toutes les applications qui ne seront pas utilisées pour rendre OwnCloud plus fluide. Je ne conserve pour ma part que "Calendrier" et "Contacts".

Dans _Administration_, décochez les autorisations de partage qui ne sont pas utiles, et sélectionnez `cron` dans le mode de mise à jour.

Nous pouvons alors commencer à créer des carnets d'adresse et des calendriers depuis l'interface web. Celle-ci fournit des liens `cardDav` et `calDav` qui peuvent ensuite être renseignés, accompagnés de votre nom d'utilisateur et de votre mot de passe OwnCloud, sur vos différents ordinateurs et périphériques.
