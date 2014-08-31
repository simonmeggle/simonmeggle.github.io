---
title: Static website <br/> with <em>Jekyll</em>
---

At the beginning of the Internet, there were **static sites**: each web page was written "by hand" using a text editor, and then put online. The disadvantages are many, especially the need to duplicate the same changes on any pages[^dupliquer], to know HTML and to have his computer available to edit pages. The advent of CSS, which allows to separate actual content from its presentation format and to share it between pages has not changed this fact[^css].

It was then that appeared **dynamic sites**: programming languages ​​running on the server side, such as PHP, helped the rise of [CMS](https://en.wikipedia.org/wiki/Content_management_system), which made possible to create sites and change their content directly from a browser, thus allowing the emergence of sites, blogs, forums accessible to the greatest number. This is for example the case of [*Spip*](http://www.spip.net/), [*Dotclear*](http://dotclear.org/) or [*WordPress*](https://wordpress.com/). However, these systems are not without disadvantages:

- ils sont très sensibles aux failles de sécurité, ce qui implique de surveiller attentivement les mises à jour et les logs ;
- ils sont consommateurs de ressources serveur, nécessitant des hébergements spécifiques pour les gros volumes de visiteurs ;
- ils supportent mal les montées en charge, et sont ainsi très sensibles aux attaques DDoS ou aux affluences de visiteurs[^affluence] ;
- ils constituent souvent de vraies usines à gaz, surdimensionnées vis-à-vis des besoins et nécessitant des bases de données.

Depuis quelques années, les **sites statiques** font leur retour en grâce avec l'apparition des *générateurs de sites statiques*. Sur la base de simples fichiers textes, un programme génère un site composé uniquement de pages statiques qu'il suffit ensuite d'héberger. Ainsi, les problèmes de sécurité sont presque inexistants, il est possible de s'héberger sur un serveur très modeste[^raspberry] ou au contraire d'obtenir d'excellentes performances et de supporter de très fortes montées en charge en utilisant un [CDN](https://fr.wikipedia.org/wiki/Content_delivery_network) comme [*Cloudflare*](https://www.cloudflare.com/) ou [*Cloudfront*](http://aws.amazon.com/fr/cloudfront/)[^cloudfront]. 

Il est de plus possible de suivre toutes les modifications et de travailler collaborativement grâce à `git`[^git], de rédiger ses articles en ligne et de générer son site à la volée à l'aide de services comme [*GitHub*](https://pages.github.com/) et [*Prose*](http://prose.io), ou d'avoir un système de commentaires avec [*Disqus*](https://disqus.com/). 

Dans cet article, nous allons voir comment installer (I) et utiliser (II) le générateur de site statiques [*Jekyll*](http://jekyllrb.com/) pour créer et modifier un site simple.

## Premier site avec *Jekyll*

Dans un premier temps, nous allons voir comment installer *Jekyll* sur votre machine, pour créer votre premier site et obtenir un serveur local permettant de l'observer dans votre navigateur.

### Installation de *Jekyll* 

**Sur *Linux***, installez directement la dernière version stable de [*Ruby*](https://packages.debian.org/stable/ruby)[^rvm], accompagné de ses [outils de développement](https://packages.debian.org/stable/ruby-dev) et de [gem](https://packages.debian.org/stable/rubygems). Sous *Debian*, il suffit d'installer les paquets suivants :
{% highlight sh %}
sudo apt-get install ruby ruby-dev libgsl-ruby rubygems
sudo gem install jekyll
{% endhighlight %}

**Sur *Mac OS X***, commencez par installer [*Homebrew*](http://brew.sh/)[^xcode] puis [*Ruby version manager*](http://rvm.io/) avec la dernière version stable de *Ruby*, pour pouvoir ensuite installer *Jekyll* :
{% highlight sh %}
ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
\curl -L https://get.rvm.io | bash -s stable --ruby
source ~/.rvm/scripts/rvm
gem install jekyll
{% endhighlight %}

**Sur *Windows*** enfin, l'installation est moins aisée : cependant, [Julian Thilo](http://jekyll-windows.juthilo.com/) a écrit un [guide très détaillé](http://jekyll-windows.juthilo.com/) sur les façons d'y installer *Jekyll*.

### Création d'un nouveau site

La commande `jekyll new monsite` permet d'obtenir le code source d'un site fonctionnel dans le dossier `monsite`. Dans ce dossier, vous pouvez le générer avec `jekyll build`. Le site est alors créé dans `_site/`.

En une commande, il est possible de générer le site et de créer un serveur local pour visualiser le site produit : utilisez `jekyll serve` pour pouvoir l'observer à l'adresse `http://localhost:4000`. Il est également possible de regénérer le site à chaque modification du code source[^serve] avec `jekyll serve -w`, qui sera de loin la commande la plus utile lorsque vous utiliserez régulièrement *Jekyll*.


### Arborescence

Le code source d'un site *Jekyll* s'organise selon plusieurs dossiers :

- **`_posts/`** dans lequel seront placés[^arborescence] tous les articles de votre site, au format `aaaa-mm-jj-nom-du-post.md` ;
- **`_layouts/`** qui va contenir la maquette du site, c'est-à-dire tout ce qui entourera nos articles ;
-  **`_includes/`**, qui contiendra des codes que vous pouvez inclure[^include] dans différentes pages si vous en avez besoin régulièrement.

Le répertoire de votre site pourra alors ressembler à :

{% highlight r %}
monsite/
       ├──  _includes/
       ├──  _layouts/
        │           ├── default.html
        │           ├── page.html
        │           └── post.html
       ├──  _posts/
        │           └── 2014-08-24-site-statique-avec-jekyll.md
       ├──  medias/
        │           ├── style.sass
        │           ├── script.js
        │           └── favicon.ico
       ├──  index.html
       ├──  rss.xml
       └──  _config.yml
{% endhighlight %} 

Vous pouvez ajouter n'importe quel autre dossier, ou fichier, dans le répertoire de votre site. Tant qu'ils ne commencent pas par un tiret bas, ceux-ci seront directement générés au même emplacement par *Jekyll*. 

## Utilisation de *Jekyll*

Maintenant ce premier site créé, nous allons voir comment le faire évoluer en rédigeant des articles et en utilisant leurs métadonnées. 

Pour créer un article, il suffit de créer dans le dossier `_posts` un fichier dont le nom est au format `aaaa-mm-jj-nom-du-post.md`[^drafts]. Ce fichier se compose de deux parties : l'**en-tête** où sont situées les métadonnées de l'article, et le **contenu** de l'article à proprement parler.

### Déclarer les métadonnées des fichiers

L'en-tête permet de déclarer les métadonnées de l'article ; celles-ci pourront par la suite être appelées ou testées dans le reste du site[^meta]. Elle est présente en début de fichier, sous la forme suivante :

{% highlight r %}
---
layout: default
title: Mon titre
---
{% endhighlight %} 

Seule la variable `layout` est obligatoire : elle définit le fichier que *Jekyll* doit utiliser dans le dossier `_layouts/` pour construire la page autour de l'article. Il est également usuel de définir `title` qui permet de définir le titre de l'article[^variable].

Il est également possible de définir des variables "par défaut" qui concerneront tous les articles d'un dossier. Par exemple, pour ne pas avoir à indiquer `layout: default` au sein de tous les articles placés dans `_posts/`, il est possible de la définir par défaut dans `_config.yml` :

{% highlight ruby %}
defaults:
  -
    scope:
      path: "_posts"
    values:
      layout: "default"
{% endhighlight %} 

### Écriture des articles avec Markdown

Par défaut, les articles s'écrivent en [*Markdown*](http://daringfireball.net/projects/markdown/basics). L'objectif de ce langage est de proposer une syntaxe très simple permettant de rédiger les articles en évitant les balises HTML les plus courantes. Ainsi, "*italique*" s'obtient `*italique*`, et "**gras**" avec `**gras**`. Il reste cependant toujours possible d'utiliser HTML au sein des articles.

Depuis sa deuxième version, *Jekyll* utilise [*Kramdown*](http://kramdown.gettalong.org/) qui ajoute de nombreuses fonctionnalités telles que la possibilité d'attribuer des classes aux éléments, les notes de bas de page, les listes de définition, les tableaux[^kramdown]... 


### Utilisation des métadonnées

Toute métadonnée "`variable`" déclarée dans l'entête peut être appelée, dans n'importe quel fichier, à l'aide d'une balise `{%raw%}{{page.variable}}{%endraw%}` qui retournera alors sa valeur. 

Il est également possible d'effectuer des tests :
{% highlight r %}{% raw %}
{% if page.variable == 'value' %}
    banane
{% else %}
    noix de coco
{% endif %}
{%endraw%}
{% endhighlight %} 

Nous pouvons aussi, par exemple, effectuer des boucles sur l'ensemble des articles répondant à certaines conditions :

{% highlight r %}{% raw %}
{% assign posts=site.posts | where: "variable", "value" %}
{% for post in posts %}
    {{ post.lang }}
{% endfor %} 
{% endraw %}
{% endhighlight %} 

Bien que la [syntaxe](https://github.com/Shopify/liquid/wiki/Liquid-for-Designers)[^liquid] ne soit pas toujours très élégante à utiliser, le grande nombre de [variables disponibles](http://jekyllrb.com/docs/variables/), auxquelles s'ajoutent les métadonnées personnalisées que vous créerez ainsi que les nombreux [filtres et commandes](https://github.com/Shopify/liquid/wiki/Liquid-for-Designers), peuvent être extrêmement efficaces.


---

### Et bien plus...

Cet article n'a pas prétention à constituer davantage qu'une très brève introduction à *Jekyll*. Pour personnaliser votre site davantage, lisez en priorité l'[excellente documentation de *Jekyll*](http://jekyllrb.com/docs/home/), bien tenue à jour, ainsi que les nombreuses références que vous trouverez sur Internet. 

Vous pouvez également consulter sur ce site trois autres articles à propos de *Jekyll* :

- [créer un site multilingue avec *Jekyll*](/site-multilingue-avec-jekyll/) comme cela a été réalisé ici ;
- [servir un site statique à l'aide de CloudFront](/site-statique-avec-cloudfront/) pour obtenir des performances maximales en termes de disponibilité et de vitesse ;
- **héberger _Jekyll_ sur GitHub** (article à venir) pour pouvoir suivre et modifier votre site en ligne, en le générant à la volée.

Enfin, parcourir les [codes sources de sites utilisant *Jekyll*](https://github.com/jekyll/jekyll/wiki/Sites)[^source], pour vous inspirer, ne peut être qu'une excellente idée. 

[^dupliquer]: Il en découlait une  réelle difficulté à faire évoluer un site sur le long terme.
[^css]: De surcroît, la très faible interopérabilité entre navigateurs et le très mauvais support de CSS par Microsoft Internet Explorer, alors très dominant, ont fortement retardé son utilisation.
[^git]: En effet, les sources ne sont constituées que de fichiers textes.
[^affluence]: Il n'est pas rare qu'un site devienne indisponible, par exemple lors d'un événement important ou en raison d'un lien publié sur un site d'actualités.
[^raspberry]: Par exemple, un [Raspberry Pi](http://www.raspberrypi.org/) avec nginx peut répondre à plusieurs centaines de connexions par seconde, ce qui est impensable avec un site dynamique.
[^cloudfront]: Les façons d'héberger un site statique sur [*Amazon S3*](http://aws.amazon.com/fr/s3/) et [*Cloudfront*](http://aws.amazon.com/fr/cloudfront/) sont détaillés dans "[Site statique avec *Cloudfront*](/site-statique-avec-cloudfront/)".
[^rvm]: Il est également possible d'installer [Ruby version manager](http://rvm.io/).
[^xcode]: Si vous ne les avez pas déjà, une fenêtre vous proposera d'installer les "outils en ligne de commande Xcode", ce qu'il faut accepter pour continuer.
[^serve]: Cette option ne prend cependant pas pas en compte les modifications de `_config.yml`.
[^arborescence]: L'arborence interne du dossier `_post` est laissée entièrement libre.
[^include]: En plaçant un fichier dans `_includes`, il vous sera possible de l'importer n'importe où avec `{%raw%}{{include nom-du-fichier}}{%endraw%}`. Il est même possible de lui passer des variables.
[^drafts]: Il est également possible de créer des articles dans le dossier `_drafts` sans date dans le nom de fichier : cela permet de créer des brouillons d'article, qui n'apparaîtront pas dans la liste des articles disponibles mais restent accessibles depuis leur adresse directe.
[^source]: Vous êtes notamment libres de consulter le [code source du présent site](https://github.com/sylvaindurand/sylvaindurand.github.io) pour voir comment celui-ci est conçu.
[^variable]: Il existe malgré tout des variables spécifique à *Jekyll* dont le rôle est particulier : `permalink` permet par exemple d'indiquer l'adresse à laquelle l'article sera accessible.
[^kramdown]: La [documentation de Kramdown](http://kramdown.gettalong.org/quickref.html) présente efficacement l'ensemble des possibilités offertes par le moteur et la syntaxe permettant d'y parvenir.
[^liquid]: La [documentation officielle de liquid](https://github.com/Shopify/liquid/wiki/Liquid-for-Designers) permet de rendre compte des possibilités offertes par le langage.
[^meta]: Cf. *infra*.


*[HTML]: HyperText Markup Language
*[PHP]: PHP: Hypertext Preprocessor
*[CMS]: Content management system
*[DDoS]: Distributed denial of service
*[CDN]: Content delivery network
*[CSS]: Cascading Style Sheets
