---
title: Rendre <em>Jekyll</em> <br/> multilingue
redirect_from: /site-multilingue-avec-jekyll/
---

J<em>ekyll</em> laisse une grande liberté de choix en permettant de mettre simplement en place des fonctionnalités qui ne sont pas prévues par son moteur. C'est notamment le cas lorsque l'on souhaite proposer son site en plusieurs langues : alors que la plupart des CMS sont très rigides ou nécessitent des plugins, quelques filtres suffisent ici pour obtenir le résultat désiré.

Cet article a pour objectif de présenter une façon de créer un site multilingue avec *Jekyll*. Il suppose que celui-ci est bien installé[[l'article [Site statique avec *Jekyll*]({{site.base}}/site-statique-avec-jekyll/) décrit comment installer et utiliser *Jekyll* pour obtenir un site simple]] et que vous savez l'utiliser pour générer un site simple.

### Objectifs
Notre site pourra être traduit en autant de langues que souhaité ; dans les exemples qui suivront, il comptera trois langues : anglais, français et chinois. Chaque page pourra elle-même être traduite ou non dans ces différentes langues[[quelle que soit la langue, il peut exister des pages qui ne sont pas forcément traduites dans toutes les autres]]. Quelle que soit la page affichée, l'intégralité du contenu --- article, date, menus, URL --- doit être dans la même langue.

Un sélecteur de langue tel que celui présent en haut à droite de ce site permettra pour chaque page d'indiquer la langue en cours et ses traductions disponibles[[les différents liens de ce sélecteur doivent renvoyer vers la traduction de la page en cours, et non vers la page d'accueil traduite]].

Tout cela fonctionnera sans plugin, afin d'assurer une meilleure compatibilité avec les futures versions de *Jekyll* et de pouvoir générer le site en mode `safe` et donc l'héberger sur [GitHub Pages](https://pages.github.com/).

## Principe

### Organisation des fichiers

L'intégralité des pages vont être rangées dans le dossier `_posts` à la racine de notre site. En son sein, créer un dossier par langue permet de rester organisé tout en définissant globalement la langue des articles[[il est tout à fait possible de ranger différemment les articles, mais il sera alors nécessaire de spécifier manuellement la langue de chaque article par la suite dans chaque entête]] :

```r
_config.yml
_layouts/
_posts/
        en/
                2014-09-01-hello-world.md
                0000-01-01-index.md
        fr/
                2014-09-01-bonjour-monde.md
                0000-01-01-journal.md
        zh/
                2014-09-01-你好世界.md
                0000-01-01-首页.md
```

Au sein de ceux-ci, l'organisation des fichiers en sous-dossiers est entièrement libre. La seule contrainte est que tous les fichiers doivent avoir un nom de fichier indiquant la date, suivi de l'identifiant qui apparaîtra dans l'URL.

Affectons alors une variable `lang` à chacun de ces dossiers[[il est également possible d'indiquer la langue dans les entêtes de chaque fichier]], ce qui nous permettra par la suite à détecter la langue et les traductions. Pour cela, nous indiquons dans `_config.yml` :

```ruby
defaults:
  -
    scope:
      path: _posts/en
    values:
      layout: default
      lang: en
  -
    scope:
      path: _posts/fr
    values:
      layout: default
      lang: fr
  -
    scope:
      path: _posts/zh
    values:
      layout: default
      lang: zh
```

### Choix des URL

Par défaut, *Jekyll* génère les URL à partir du nom des fichiers, de la forme `/2014/09/01/bonjour-monde.html`. Comme sur ce site, il est possible[[les possibilités offertes sont présentées dans la [documentation](http://jekyllrb.com/docs/permalinks/) de *Jekyll*]] de n'afficher que `/bonjour-monde/` en ajoutant dans `_config.yml` :

```ruby
permalink: /:title/
```

Nous pouvons également spécifier individuellement une adresse pour chaque fichier en indiquant la variable `permalink` dans son entête[[c'est par exemple le cas pour la page d'accueil, que l'on place à la racine en indiquant `permalink: /` dans l'entête]].




### Attribution d'un identifiant pour chaque article

Jusqu'ici, rien ne relie les différentes versions d'une même page. Pour ce faire, nous pourrions utiliser :

 - *la date*, mais plusieurs articles différents pourraient avoir la même ou, au contraire, plusieurs versions d'un même article peuvent avoir deux dates différentes ;
 - *le nom du fichier*, mais il est préférable d'avoir des noms de fichiers différents pour traduire les URL.

C'est pourquoi le plus simple est d'attribuer à chaque article un *identifiant* dont la valeur sera identique pour chaque version :

```python
---
title: Bonjour monde !
name: hello
---
```



## Liens entre les deux traductions

### Liste des articles par langue

Les pages affichant la liste des articles ne doivent afficher que ceux qui sont dans la bonne langue, ce qui peut être atteint facilement grâce à la métadonnée `lang`. Le code suivant permet d'afficher l'ensemble des articles de la bonne langue :

```html
{% raw %}
{% assign posts=site.posts | where:"lang", page.lang %}
<ul>
{% for post in posts %}
    <li class="lang">
        <a href="{{ post.url }}" class="{{ post.lang }}">{{ post.title }}</a>
    </li>
{% endfor %}
</ul>
{% endraw %}
```

Pour ne pas afficher certaines pages, comme par exemple celles qui listent les articles, il suffit d'indiquer "`type: pages`" dans leurs métadonnées et de rajouter dans `assign` la condition "`| where:"type", "posts"`".


### Sélecteur de langue

Pour créer un sélecteur de langue, comme celui présent en haut à droite de cette page, la démarche est très similaire à celle présentée au paragraphe précédent. On affiche la langue de toutes les versions existantes, y compris l'article en cours, en triant par dossier pour toujours avoir le même ordre :

```html
{% raw %}
{% assign posts=site.posts | where:"name", page.name | sort: 'path' %}
<ul>
{% for post in posts %}
    <li class="lang">
        <a href="{{ post.url }}" class="{{ post.lang }}">{{ post.lang }}</a>
    </li>
{% endfor %}
</ul>
{% endraw %}
```

Pour emphaser la langue de la version affichée, il suffit d'utiliser CSS[[pour cela, il faut bien déclarer l'attribut `lang` de la balise `html` en indiquant `<html lang="{{ page.lang }}">` dans le *layout*]]. Par exemple, pour la mettre en gras :

```css
.en:lang(en), .fr:lang(fr), .zh:lang(zh){
    font-weight: bold;
}
```

## Peaufinage

### Traduction des éléments du site
En dehors du contenu des articles, il est également nécessaire de traduire les différents éléments qui composent le site : textes des menus, du haut et de bas de page, certains titres...

Pour cela, on peut indiquer des traductions dans `_config.yml`[[depuis la deuxième version de *Jekyll*, il est également possible de placer ces informations dans le dossier [_data](http://jekyllrb.com/docs/datafiles/)]]. Ainsi, dans l'exemple suivant, `{% raw %}{{site.t[page.lang].home}}{% endraw %}` génèrera `Home`, `Accueil` ou `首页` selon la langue de la page :

```python
t:
  en:
    home:  "Home"
  fr:
    home:  "Accueil"
  zh:
    home:  "首页"
```

Il est possible d'utiliser cette technique pour générer les menus des différentes versions du site. Ainsi, dans le cas d'un menu à deux éléments comme sur ce site, on indique dans `_config.yml` :

```python
t:
  en:
    home:
      name: "Home"
      url: "/"
    about:
      name: "About"
      url: "/about/"
  fr:
    home:
      name: "Accueil"
      url: "/accueil/"
    about:
      name: "À propos"
      url: "/a-propos/"
  zh:
    home:
      name: "首页"
      url: "/首页/"
    about:
      name: "关于"
      url: "/关于/"
```

Le menu peut alors être généré à l'aide d'une boucle :

```html
{% raw %}
<ul>
  {% for menu in site.t[page.lang] %}
    <li><a href="{{menu[1].url}}">{{menu[1].title}}</a></li>
  {% endfor %}
</ul>
{% endraw %}
```


### Traduction des dates
À ce stade, tout peut être traduit sur le site à l'exception des dates,  générées automatiquement par *Jekyll*. Les formats courts, composés uniquement de chiffres, peuvent être adaptés sans difficulté. Selon la langue de la page, nous cherchons à obtenir :

- en anglais : "2014/09/01" ;
- en français : "01/09/2014" ;
- en chinois : "2014年9月1号".

Pour cela, il suffit d'utiliser le code suivant, qu'il est possible ensuite de placer dans le dossier `_includes` afin de l'utiliser à plusieurs reprises :

```python
{% raw %}
{% if page.lang == 'en' %}
    {{ page.date | date: "%d/%m/%Y" }}
{% endif %}

{% if page.lang == 'fr' %}
    {{ page.date | date: "%Y-%m-%d" }}
{% endif %}

{% if page.lang == 'zh' %}
    {{ page.date | date: "%Y年%-m月%-d号" }}
{% endif %}
{% endraw %}
```


Pour les dates longues, il est possible d'utiliser astucieusement les filtres de date et les remplacements pour obtenir n'importe quel format. Par exemple, si nous cherchons à obtenir :

- en anglais : "1<sup>st</sup> of September 2014" ;
- en français : "1<sup>er</sup> septembre 2014".

Nous utilisons alors le code suivant :

```python
{% raw %}
{% assign d = page.date | date: "%-d" %}
{% assign m = page.date | date: "%-m" %}

{% if page.lang == 'en' %}
{{ d }}<sup>{% case d %}
  {% when '1' or '21' or '31' %}st
  {% when '2' or '22' %}nd
  {% when '3' or '23' %}rd
{% else %}th
{% endcase %}</sup>
of {{ page.date | date: "%B %Y"}}
{% endif %}

{% if page.lang == 'fr' %}
{{ d }}{% if d == "1" %}<sup>er</sup>{% endif %}
{% case m %}
  {% when '1' %}janvier
  {% when '2' %}février
  {% when '3' %}mars
  {% when '4' %}avril
  {% when '5' %}mai
  {% when '6' %}juin
  {% when '7' %}juillet
  {% when '8' %}août
  {% when '9' %}septembre
  {% when '10' %}octobre
  {% when '11' %}novembre
  {% when '12' %}décembre
{% endcase %}
{{ page.date | date: "%Y"}}
{% endif %}
{% endraw %}
```

Il est à nouveau possible de placer ce code dans un fichier `date.html` placé dans le dossier `_includes` pour pouvoir l'appeler simplement.

## Accès au site et référencement

Les pages étant entièrement statiques, il est difficile de deviner la langue de nos visiteurs pour envoyer la bonne version, que ce soit en détectant les entêtes envoyées par le navigateur ou en se basant sur sa localisation géographique. Néanmoins, il est possible d'améliorer le référencement en indiquant aux moteurs de recherche les pages qui constituent les traductions d'un seul et même contenu[[ainsi, les utilisateurs trouvant notre contenu par un moteur de recherche devraient se voir proposer automatiquement la bonne traduction]].

Pour ce faire, deux solutions sont possibles : [intégrer une balise `<link>`](https://support.google.com/webmasters/answer/189077?hl=fr) dans notre page, ou [l'indiquer dans un fichier `sitemaps.xml`](https://support.google.com/webmasters/answer/2620865?hl=fr).

### Avec la balise *link*

Il suffit d'indiquer dans la partie `<head>` chaque page, l'ensemble des traductions de la page en cours[[il convient cependant de faire attention d'utiliser les bons [identifiants de langue](https://support.google.com/webmasters/answer/189077?hl=fr) pour qu'ils soient reconnus]]. Nous pouvons pour cela d'utiliser le code suivant, semblable à ceux présentés précédemment :

```html
{% raw %}
{% assign posts=site.posts | where:"name", page.name %}
{% for post in posts %}
  {% if post.lang != page.lang %}
    <link rel="alternate" hreflang="{{post.lang}}" href="{{post.url}}" />
  {% endif %}
{% endfor %}
{% endraw %}
```

### Avec un fichier *sitemaps*

Le fichier `sitemaps.xml`, qui permet aux moteurs de recherche de connaître les pages et la structure de votre site, [permet également d'indiquer aux moteurs de recherches quelles pages sont les différentes versions d'un même contenu](https://support.google.com/webmasters/answer/2620865?hl=fr).

Pour cela, il suffit d'indiquer l'intégralité des pages du site (quelle que soit leur langue) dans des éléments `<url>` et pour chacun d'entre eux l'ensemble des versions qui existent, y compris celle que l'on est en train de décrire.

Ce fichier peut être généré automatiquement par *Jekyll* en créant un fichier `sitemaps.xml` à la racine du site contenant :

```xml
{% raw %}
---
layout:
permalink: /sitemaps.xml
---
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
  {% for post in site.posts %}
  <url>
    <loc>http://domain.tld{{ post.url }}</loc>
    {% assign versions=site.posts|where:"name",post.name %}
    {% for version in versions %}
      <xhtml:link rel="alternate" hreflang="{{ version.lang }}" href="http://domain.tld{{ version.url }}" />
    {% endfor %}
    <lastmod>{{ post.date | date_to_xmlschema }}</lastmod>
    <changefreq>weekly</changefreq>
  </url>
  {% endfor %}
</urlset>
{% endraw %}
```

