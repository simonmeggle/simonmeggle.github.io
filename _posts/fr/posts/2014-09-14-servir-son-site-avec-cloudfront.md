---
title: Servir son site <br/> avec <em>Cloudfront</em>
redirect_from: /site-statique-avec-cloudfront/
---

Les sites statiques ont pour principal intérêt de pouvoir être stockés dans le *nuage*, c'est-à-dire sur des serveurs de contenu permettant de les délivrer très rapidement, à moindre coût, avec une fiabilité et une sécurité extraordinaire.

Ce billet montrera comment un site statique[[qu'il soit produit par un générateur comme [*Jekyll*](http://jekyllrb.com), [*Pelican*](http://docs.getpelican.com/) ou encore [*Hyde*](http://hyde.github.io), ou réalisé à la main]] peut être hébergé sur les [services web d'*Amazon*](http://aws.amazon.com/fr/) (*AWS*), et notamment hébergé sur [*S3*](http://aws.amazon.com/fr/s3/) et servi à l'aide de [*Cloudfront*](http://aws.amazon.com/fr/cloudfront/). De cette façon, le site sera disponible très rapidement depuis n'importe où, supportera n'importe quelle montée en charge, sans préoccupation de maintenance ou de sécurité, et cela à un coût presque nul[[avec un faible trafic, il ne vous en coûtera qu'environ un dollar]].

Nous utiliserons pour cela :

* [*S3*](http://aws.amazon.com/fr/s3/) pour héberger les fichiers avec une haute disponibilité ;
* [*Cloudfront*](http://aws.amazon.com/fr/cloudfront/) pour servir les données avec une latence minimale ;
* [*Route 53*](http://aws.amazon.com/fr/route53/) pour utiliser notre propre nom de domaine ;
* [*Awstats*](http://awstats.sourceforge.net/) pour analyser les statistiques de notre site.




## Hébergement sur *S3*

Après avoir créé un compte [*AWS*](http://aws.amazon.com/fr/), allons dans la [console](https://console.aws.amazon.com/) puis dans [*S3*](https://console.aws.amazon.com/s3/) : ce service nous permettra de stocker les fichiers du site internet.

### Création des *buckets*
Dans notre exemple, les pages seront accessibles depuis l'adresse `www.domain.tld`. Pour éviter de perdre des utilisateurs, la racine `domain.tld` redirigera vers celle-ci. Créons deux buckets (avec `Create bucket`) portant exactement ces mêmes noms  : `www.domain.tld` et `domain.tld`.

### Paramètre du *bucket* hébergeant le site
Dans les propriétés de `www.domain.tld`, activons l'hébergement de fichiers (`Static Website Hosting` puis `Enable website hosting`) : c'est l'occasion de choisir des pages d'accueil (`index.html`) et d'erreur (`erreur.html`). Ce site sera disponible depuis l'adresse `Endpoint` qui est indiquée : *notez-là*, nous en aurons besoin à la section suivante.

### Paramètres de l'autre *bucket* pour rediriger vers le site
Dans les propriétés de `domain.tld`, on va également dans `Static Website Hosting` mais pour y sélectionner `Redirect all requests` : on indique `www.domain.tld`. Ce *buckets* restera vide.

C'est tout ! Depuis l'adresse `Endpoint`, on peut observer tous les fichiers stockés dans le bucket `www.domain.tld`. Il est possible d'en transmettre depuis l'interface Web, nous verrons dans la dernière partie comment simplement envoyer son site sur *S3* depuis un terminal.


## Service par *Cloudfront*

*S3* permet de stocker les données, mais celles-ci ne sont présentes qu'à un endroit unique. Des données stockées à Dublin en Irlande pourront sembler relativement rapides pour un utilisateur à Paris (environ 200 ms de chargement pour l'accueil de ce site) mais moins à New-York (500 ms) ou à Shanghai (1<span style="white-space:nowrap">&thinsp;</span>300 ms).

*Amazon Cloudfront* est un [CDN](http://fr.wikipedia.org/wiki/Content_delivery_network), et permet donc de rapprocher géographiquement nos données de ceux qui vont venir visiter notre site : les données stockées sur *Amazon S3* sont dupliquées sur différentes machines éparpillées dans le monde. Cela permet de réduire fortement le temps d'accès : environ 100 ms à Paris, à New-York ou à Shanghai pour ce site.

En contrepartie, il existe un délai de propagation entre le moment où vous effectuez des modifications sur vos fichiers stockés sur *S3* et lorsque celles-ci seront mises à jour sur *Cloudfront*. Nous verrons dans la dernière partie comment automatiquement indiquer à *Cloudfront* que les données sont à mettre à jour, ce qui réduit ce laps de temps à quelques minutes.

### Création de la distribution

Dans la console de gestion d'*AWS*, choisissez le service *Cloudfront* et sélectionnez `Create Distribution`, puis `Web`.

Dans `Origin Domain Name`, nous indiquons l'adresse que vous avez précédemment copiée, de type `www.domain.tld.s3-website-eu-west-1.amazonaws.com`. Le champ va proposer automatiquement un autre choix (de type `www.domain.tld.s3.amazonaws.com`) qu'il *ne faut pas* sélectionner : les adresses se finissant par `/` ne redirigeraient plus vers `/index.html`. On indique un identifiant au choix dans `Origin ID`.

Nous laissons tous les autres champs par défaut, à l'exception de `Alternate Domain Names` dans lequel nous indiquons le nom de domaine où s'affichera notre site : `www.domain.tld`. Précisons la page d'accueil dans `Default Root Object` : `index.html`.

Notre distribution créée, nous pouvons l'activer avec `Enable`. Le statut `InProgress` signifie que *Cloudfront* est en train de répandre des copies de nos fichiers. `Deployed` signifie que le service est pleinement opérationnel. La liste affiche enfin le lien de la distribution, dans notre cas `http://d2whzwio4uka4g.cloudfront.net`. Si vous avez déjà envoyé un fichier sur *S3*, vous pouvez vérifier que tout fonctionne bien depuis cette adresse.



## Noms de domaines avec *Route 53*
Notre site pourrait être pleinement opérationnel, mais à une adresse de type `http://d2whzwio4uka4g.cloudfront.net`. Le service *Route 53* va nous permettre de définir notre propre nom de domaine.

### Création de la zone
Dans la console, sélectionnons *Route 53* puis `Create Hosted Zone`. Dans `Domain Name`, on indique notre nom de domaine sans sous-domaine : `domain.tld`.

### Redirection DNS
En cliquant sur la zone nouvellement créée apparaît une liste : repérez la ligne de type `NS`, qui dans son champ `Value` affiche quatre adresses.

Chez votre registar, changez vos DNS en entrant à la place de ceux existants ces quatre adresses dans l'ordre. Les changements peuvent mettre plusieurs heures à être opérationnels.

### Attache du domaine principal avec *Cloudfront*
Revenu dans *Route 53*, dans `domain.tld`, nous allons créer trois enregistrements avec `Create Record Set` :

* `www.domain.tld` (entrez  `www` dans `name`), sera de type `A` ; dans `Alias`, sélectionnez la distribution *Cloudfront* qui devrait être proposée ;
* `domain.tld` (laissez `name` vide) sera également de type `A` : son alias redirigera vers le *bucket* de même nom, proposé automatiquement.

Il reste bien sûr possible de rediriger des sous-domaines vers d'autres services (avec les champs NS, A ou CNAME) ou d'utiliser un service de mails (avec les champs MX).



Désormais, un utilisateur tapant `domain.tld` ou `www.domain.tld` atteindra les buckets de mêmes noms (grâce à *Route 53*), qui redirigent vers l'adresse `www.domain.tld` (grâce aux réglages des *buckets* dans *S3*). Ils y rejoignent ceux qui ont demandé dès le début `www.domain.tld`.

Cette adresse `www.domain.tld` pointe directement (grâce à *Route 53*) vers la distribution *Cloudfront*, qui elle-même sert les fichiers présents dans le bucket `www.domain.tld`. Il ne reste maintenant qu'à envoyer notre site sur *Amazon S3*.




## Déployer *Jekyll* dans les nuages

Nous allons maintenant créer un fichier `sh` qui va nous permettre, en une commande, de générer notre site et de mettre à jour sur *Amazon S3* tous les fichiers qui ont été modifiés depuis la version précédente, et d'indiquer à *Cloudfront* qu'il va falloir les mettre à jour.


### Prérequis : s3cmd

Nous allons utiliser `s3cmd` pour mettre à jour notre site directement sur *S3*. Installez la dernière version de développement[[il est nécessaire d'installer au moins la version 1.5]] et non la version stable afin de pouvoir invalider les fichiers sur *Cloudfront* (c'est-à-dire notifier à *Cloudfront* qu'un fichier a été modifié et qu'il va devoir mettre à jour ses copies).

Sous Mac OS, avec *Homebrew*, on installe `s3cmd` avec l'option `devel`, ainsi que `gnupg` pour des transferts sécurisés :

```bat
brew install --devel s3cmd
brew install gpg
```

Nous devons maintenant donner l'autorisation à `s3cmd` d'intéragir avec notre compte. Depuis la rubrique [Security Credentials](https://console.aws.amazon.com/iam/home?#security_credential) de la console, allez dans `Access Key` et générez une clef d'accès et une clef secrète. Conservez-les précieusement. On lance alors l'assistant de configuration avec `s3cmd --configure`.


Par ailleurs, afin d'optimiser les images, nous allons installer `jpegoptim` et `optipng` :

```bat
brew install jpegoptim
brew install optipng
```


### Génération de Jekyll et compression des fichiers

On commence par générer jekyll dans le dossier `_site` :

```bat
jekyll build
```

L'utilisation du plugin `jekyll-press` permet d'optimiser les fichiers HTML, JS et CSS. Si `jpegoptim` et `optipng` sont installés sur le système, nous pouvons optimiser les pages et les images :

```bat
find _site -name '*.jpg' -exec jpegoptim --strip-all -m80 {} \;
find _site -name '*.png' -exec optipng -o5 {} \;
```

Afin d'accélérer encore un peu plus le chargement du site, nous compressons l'ensemble des fichiers HTML, CSS et JS, c'est-à-dire les fichiers qui sont hors de `static/` :

```bat
find _site -path _site/static -prune -o -type f \
-exec gzip -n "{}" \; -exec mv "{}.gz" "{}" \;
```

### Déploiement des fichiers vers *Amazon S3*

Nous pouvons alors utiliser `s3cmd` pour déployer notre site en ligne. Seuls les fichiers mis à jour depuis la dernière synchronisation sont envoyés. Nous utiliserons notamment les options suivantes :

* `acl-public` rend public les fichiers envoyés ;
* `cf-invalidate` actualise les fichiers servis par *Cloudfront* ;
* `add-header` définit les entêtes (compression, durée de cache...) ;
* `delete-sync` supprime les fichiers distants inexistants en local ;
* `M` définit automatiquement le type MIME des fichiers.

Nous commençons ainsi par envoyer tous les fichiers multimédias stockés dans `static/`, en leur affectant une durée de cache de dix semaines :

```bat
s3cmd --acl-public --cf-invalidate -M \
      --add-header="Cache-Control: max-age=6048000" \
      --cf-invalidate \
      sync _site/static s3://www.domain.tld/
```

Nous envoyons tous les autres fichiers (HTML, CSS, JS), auxquels nous affectons une durée de cache de 48 heures, et nous indiquons que le contenu est compressé :

```bat
s3cmd --acl-public --cf-invalidate -M \
      --add-header 'Content-Encoding:gzip' \
      --add-header="Cache-Control: max-age=604800" \
      --cf-invalidate \
      --exclude="/static/*" \
      sync _site/ s3://www.domain.tld/
```

Enfin, nous faisons le ménage en supprimant en ligne tout ce qui n'existe plus dans notre dossier local, et on actualise la page d'accueil `index.html` sur *Cloudfront* (ce que ne fait pas `cf-invalidate`) :

```bat
s3cmd --delete-removed --cf-invalidate-default-index \
      sync _site/ s3://www.domain.tld/
```

### En une seule commande

Stockons l'intégralité des opérations précédentes en un seul fichier `_deploy.sh`, que nous plaçons à la racine de *Jekyll* :

```sh
#!/bin/sh
# Compilation de Jekyll
jekyll build

# Compression et optimisation
find _site -path _site/static -prune -o -type f \
      -exec gzip -n "{}" \; -exec mv "{}.gz" "{}" \;
find _site -name '*.jpg' -exec jpegoptim --strip-all -m80 {} \;
find _site -name '*.png' -exec optipng -o5 {} \;

# Synchronisation des médias
s3cmd --acl-public --cf-invalidate -M \
      --add-header="Cache-Control: max-age=6048000" \
      --cf-invalidate \
      sync _site/static s3://www.domain.tld/

# Synchronisation des autres fichiers
s3cmd --acl-public --cf-invalidate -M \
      --add-header 'Content-Encoding:gzip' \
      --add-header="Cache-Control: max-age=604800" \
      --cf-invalidate \
      --exclude="/static/*" \
      sync _site/ s3://www.domain.tld/

# Suppression des fichiers retirés en local
s3cmd --delete-removed --cf-invalidate-default-index \
      sync _site/ s3://www.domain.tld/
```

Il suffit alors d'exécuter la commande `sh _deploy.sh` pour mettre à jour notre site en une seule commande. Quelques minutes peuvent s'écouler avant que la mise à jour ne soit effective sur *Cloudfront*.


## Statistiques

Bien que notre site soit statique et servi par un serveur de contenu, il est tout à fait possible d'analyser les logs si l'on ne souhaite pas utiliser de système basé sur un code javascript, tel [Piwik](http://piwik.org/) ou [Google Analytics](https://www.google.fr/intl/fr/analytics/). Ici, nous automatiserons la tâche (récupération des logs, traitement et affichage des statistiques) depuis un serveur (dans notre exemple, un Raspberry Pi sous Raspbian) et nous utiliserons [*Awstats*](http://awstats.sourceforge.net/).

### Récupération des logs

Commençons par activer la création de logs par notre distribution *Cloudfront*. Dans la console de gestion d'*AWS*, choisissez le service *Amazon S3* et créez un bucket " statistiques " où seront stockées les logs en attendant d'être récupérées. Puis, dans *Cloudfront*, sélectionnez la distribution qui fournit notre site internet, puis `Distribution settings`, `Edit`, et sélectionnez ce bucket dans le champ `Bucket for Logs`.

Nous créons en local un dossier qui va récupérer ces logs, puis nous pouvons alors récupérer les logs puis les supprimer du *bucket* à l'aide de `s3cmd` :

```bat
mkdir ~/awstats
mkdir ~/awstats/logs
s3cmd get --recursive s3://statistiques/ ~/awstats/logs/
s3cmd del --recursive --force s3://statistiques/
```

### Installation et configuration d'*Awstats*

Commençons par installer et copier *Awstats* (où `www.domain.tld` est votre nom de domaine) :

```bat
sudo apt-get install awstats
sudo cp /etc/awstats/awstats.conf \
        /etc/awstats/awstats.www.domain.tld.conf
sudo nano /etc/awstats/awstats.www.domain.tld.conf
```

Dans ce fichier de configuration, modifiez les paramètres suivants pour indiquer à *Awstats* comment traiter les logs de *Cloudfront* (où `user` est votre nom d'utilisateur) :

```r
# Traitement des multiples fichiers logs au format gzip
LogFile="/usr/share/awstats/tools/logresolvemerge.pl /home/user/awstats/logs/* |"
# Format des logs générés par CloudFront
LogFormat="%time2 %cluster %bytesd %host %method %virtualname %url %code %referer %ua %query"
LogSeparator="\t"
# Nom de domaine de notre site et serveurs Cloudfront
SiteDomain="www.domain.tld"
HostAliases="REGEX[.cloudfront\.net]"
```

Enfin, nous copions les images qui seront affichées dans les rapports :

```bat
sudo cp -r /usr/share/awstats/icon/ ~/awstats/awstats-icon/
```

### Génération des statistiques

Une fois cette configuration faite, il est possible de générer les statistiques sous forme d'un fichier HTML statique l'aide de :

```bat
/usr/share/awstats/tools/awstats_buildstaticpages.pl \
    -dir=~/awstats/ -update -config=www.domain.tld \
```

Les statistiques sont désormais lisibles depuis le fichier `awstats.www.domain.tld.html`. Il est ensuite possible de le publier, de l'envoyer sur un serveur ou par mail par exemple.


### Mise à jour régulière des statistiques

Pour automatiser la génération de statistiques à intervalles réguliers, créons un fichier `stats.sh` avec `nano ~/awstats/stats.sh` qui récupère les logs et génère les statistiques :

```sh
#!/bin/sh
# Récupération des logs
s3cmd get --recursive s3://statistiques/ ~/awstats/logs/
s3cmd del --recursive --force s3://statistiques/
# Génération des logs
/usr/share/awstats/tools/awstats_buildstaticpages.pl \
    -dir=~/awstats/ -update -config=www.domain.tld \
```

Nous donnons à ce fichier les droits pour qu'il puisse être exécuté, puis créons une tâche `cron` :


```bat
sudo chmod 711 ~/awstats/stats.sh
sudo crontab -e
```

Pour générer des statistiques toutes les six heures par exemple, on y ajoute la ligne :

```r
0 */6 * * * ~/awstats/stats.sh
```
