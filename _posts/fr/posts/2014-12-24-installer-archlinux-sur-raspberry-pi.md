---
title:  Installer <em>Archlinux</em> <br/> sur Raspberry Pi
---

Est-il encore nécessaire de le présenter ? Le Raspberry Pi est un nano-ordinateur, dont la toute petite taille, la très faible consommation électrique et le très faible coût[[environ 35 € dans sa version la plus puissante, auxquels doivent s'ajouter une carte SD, un câble d'alimentation µUSB et un câble ethernet, soit moins de 50 € au total]] en font un serveur personnel ou un support de bidouillage indispensable.

Malgré sa puissance de calcul limitée, il est parfaitement possible d'en faire un serveur web, un cloud personnel pour synchroniser fichiers, calendriers et vos contacts, un NAS, une borne *Airplay*, une console de jeux rétro... ou tout cela à la fois. Quel que soit votre objectif, il est nécessaire d'y installer une distribution Linux.

Nous allons ici voir comment installer et configurer *Archlinux* sur notre Raspberry Pi, directement en ligne de commande par le réseau, ce qui signifie que nous n'aurons besoin ni de clavier, ni d'écran.

Ainsi, pour suivre ce tutoriel, vous n'aurez besoin que de  :

* un _Raspberry Pi_ modèle B ;
* une _carte SD_ d'au moins 2 Go pour y installer notre système ;
* un _câble µUSB_ pour mettre notre Raspberry Pi sous tension  ;
* un _câble éthernet_ pour brancher notre Pi à notre routeur.

![Raspberry Pi – Jonathan Rutheiser, CC BY-SA 3.0](/medias/raspberry/raspberrypi.svg)

## Installer *Archlinux*
Parmi les nombreuses distributions disponibles pour Raspberry Pi, nous allons utiliser *[ArchLinux](http://downloads.raspberrypi.org/arch/images/arch-2014-06-22/)*, en raison de sa légereté et de l'écosystème très complet qui s'est bâti autour d'elle.

### Téléchargement

Commençons par récupérer la dernière version d'*Archlinux*, dont une [image](http://downloads.raspberrypi.org/arch/images/arch-2014-06-22/ArchLinuxARM-2014.06-rpi.img.zip) est proposée sur le site de Raspberry Pi[[à la date de rédaction de cet article, la dernière image publiée sous ce format date de juin 2014 ; cela pose cependant peu de difficulté, puisque nous mettrons le système à jour dès qu'il sera installé]]. Téléchargez-là, puis extrayez là :

```bash
curl -OL http://downloads.raspberrypi.org/arch/images/arch-2014-06-22/ArchLinuxARM-2014.06-rpi.img.zip
unzip ArchLinuxARM-2014.06-rpi.img.zip
```

### Installation
Nous allons écrire l'image d'*Archlinux* précédemment téléchargée sur la carte SD. Pour cela, insérons dans notre ordinateur la carte SD qui accueillera le système.

Il nous est nécessaire de connaître le chemin d'accès à la carte SD. Sous OS X, on lance dans le terminal la commande suivante pour l'identifiant de votre carte SD (`/dev/disk2` dans l'exemple qui suit) :

```bash
diskutil list
```

Nous allons maintenant écrire l'image sur la carte. Attention, l'intégralité du contenu de la carte SD sera perdu ! Pour cela, nous entrons les commandes suivantes (où `/dev/disk2`[[sous OS X, on utilise `rdisk2` à la place de `disk2` lors de la commande `dd` pour nettement accélérer la copie]] est le chemin vers la carte SD) :


```bash
diskutil unmountDisk /dev/disk2
sudo dd if=ArchLinuxARM-2014.06-rpi.img of=/dev/rdisk2 bs=1m
sudo diskutil eject /dev/disk2
```


Nous pouvons alors éjecter la carte SD et l'insérer dans votre Raspberry Pi. Connectons celui-ci à notre réseau, et mettons-le sous tension.


## Connexion au Raspberry Pi
Nous allons accéder à notre Raspberry Pi depuis notre ordinateur, en ligne de commande à l'aide de SSH. Les utilisateurs d'OS X ou de Linux pourront directement lancer la commande `ssh` présentée ci-dessous, tandis que ceux de Windows préfèreront utiliser un logiciel comme [*PuTTY*](http://www.putty.org/). Dans le cas contraire, il est possible de connecter un clavier en USB et de connecter le Raspberry Pi à un écran à l'aide de son port HDMI.

Comme toute autre ordinateur, le Raspberry Pi est identifié sur le réseau grâce à son adresse IP. Pour nous y connecter, il est nécessaire de connaître cette dernière.

Deux possibilités s'offrent à vous :

* soit vous ne souhaitez y accéder que depuis votre réseau local, et dans ce cas il suffit de connaître quelle IP lui attribue votre routeur ;
* soit vous voulez pouvoir y accéder n'importe où[[ce sera par exemple le cas pour en faire un serveur web]], et dans ce cas votre routeur doit rediriger les demandes de l'extérieur vers votre Raspberry Pi.


### Depuis le réseau local
Après avoir branché à votre routeur puis allumé notre Raspberry Pi, il nous faut connaître son adresse IP[[sous OS X, on exécute depuis son réseau local la commande `arp -a`]].

Pour plus de confort, rendez-vous sur l'interface d'administration de votre routeur et demandez lui d'attribuer une adresse IP fixe. Ainsi, celle-ci sera toujours identique si votre routeur ou votre Raspberry doit redémarrer.

Une fois l'adresse du Raspberry Pi connue (nous prendrons `192.168.1.1` pour exemple dans la suite), nous pouvons nous connecter en SSH à notre Raspberry Pi avec la commande :

```bash
ssh root@192.168.1.1
```

Validez alors le certificat de sécurité qui est présenté, puis entrez le mot de passe par défaut `root`. Nous voilà connecté à notre Raspberry Pi !


### Depuis n'importe où
Dans beaucoup de cas, nous souhaitons que notre Raspberry Pi soit accessible depuis l'extérieur de notre réseau. Votre routeur doit posséder une IP fixe ; dans le cas contraire, il est nécessaire d'utiliser un client de DNS dynamique.

Pour cela, la façon de procéder dépend largement du modèle de votre routeur ou de votre box : connectez-vous à son interface d'administration et commencez par attribuer une IP fixe à votre Raspberry Pi. Ensuite, indiquez au routeur de toujours transférer vers cette adresse IP les ports souhaités : en particulier, le port 22 pour SSH[[si vous souhaitez configurer un serveur web par la suite, vous pouvez faire de même avec les ports 80 et 443]].

Une fois cela réalisé, nous pouvons désormais nous connecter depuis n'importe où sur internet (où `80.23.170.17` est l'IP externe de notre réseau) :

```bash
ssh root@80.23.170.17
```

Nous pouvons également attribuer un nom de domaine à notre Raspberry (notamment si celui-ci va servir de serveur web). Chez votre registar, créez pour votre `domain.tld` un champ `A` dans lequel vous indiquez l'adresse IP externe (`80.23.170.17` dans notre exemple). Une fois les modifications validées, nous pouvons accéder à notre Pi avec :

```bash
ssh pi@domain.tld
```

Validez alors le certificat de sécurité qui est présenté, puis entrez le mot de passe par défaut `raspberry`. Nous voilà connecté à notre Raspberry Pi !

## Configurer *Archlinux*

### Création des utilisateurs

Au lancement du nouveau système, commençons par changer le mot de passe administrateur :

```bash
passwd root
```

Nous pouvons par ailleurs en profiter pour créer un compte utilisateur, à qui on peut donner un droit de `sudo` :

```bash
useradd -m -g users -G wheel -s /bin/bash pi
passwd pi
pacman -S sudo
```

### Mise à jour du système

Pour mettre à jour l'intégralité[[cette commande mettra à jour aussi bien vos logiciels que les pilotes nécessaires au Raspberry Pi]] du système, on utilise simplement la commande suivante :

```bash
pacman -Suy
```


### Langue

Par défaut, le système est configuré en anglais. Afin d'obtenir une interface dans une autre langue, modifions le fichier suivant :

```bash
nano /etc/locale.gen
```

Pour le français, il suffit de décommenter la ligne `fr_FR.UTF-8`. On regénère alors les *locales* avec :

```bash
locale-gen
```

Sélectionnons alors cette locale par défaut en éditant le fichier suivant :

```bash
nano /etc/locale.conf
```

On y ajoute le contenu suivant :

```
LANG="fr_FR.UTF-8"
LANGUAGE="fr_FR:en_US"
LC_COLLATE=C
```

Au redémarrage, le terminal sera alors dans la bonne langue.

### Divers

*Archlinux* utilise par défaut l'éditeur de texte `vi`, auquel je préfère `nano` pour sa simplicité. Afin de l'utiliser par défaut, les deux commandes suivantes suffisent :

```bash
pacman -Rns vi
ln -s /usr/bin/nano /usr/bin/vi
```

Il est également possible de renommer le nom de la machine qui s'affiche dans le terminal. Par exemple :

```bash
hostname raspberry
```


### Améliorer la sécurité
Notre Raspberry Pi étant branché à un réseau, il sera soumis à de nombreuses attaques. Pour limiter les risques, il est tout d'abord possible de changer le port par défaut de SSH (22) en un port quelconque. Pour cela, modifiez le fichier suivant :

```bash
nano /etc/ssh/sshd_config
```

Changez-y la ligne indiquant `Port 22` en remplaçant `22` par le port de votre choix (par exemple, `50132`). Vous pourrez alors vous connecter en SSH comme précédemment en indiquant le paramètre `-p 50132` :

```bash
ssh pi@80.23.170.17 -p 50132
```

Par ailleurs, le paquet `fail2ban` permet d'empêcher les attaques par dictionnaire ou par *bruteforce* en lisant les logs de connexion et en bloquant les tentatives répétées de connexion avec un nom d'utilisateur ou un mot de passe incorrect. Il suffit pour cela d'installer le paquet :

```bash
pacman -S fail2ban
```

Vous pouvez surveiller régulièrement les logs pour identifier les tentatives frauduleuses de connexion avec la commande `grep 'sshd' /var/log/auth.log`.

## Conclusion
Vous disposez maintenant d'une machine pleinement fonctionnelle, accessible depuis votre réseau ou depuis internet. Si sa puissance de calcul reste limitée, il est cependant possible de l'utiliser de multiples façons :

- serveur web ;
- cloud personnel ;
- gestionnaire de flux RSS ;
- ou de téléchargements torrents ;
- NAS ;
- borne *Airplay* ;
- console de jeux rétro...

