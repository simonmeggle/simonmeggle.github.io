---
layout: default
title: Générer un site multilingue avec <em>Jekyll</em> 
trans: /multilingual-website-with-jekyll/
lang: fr
code: yes
---

J _ekyll_ est un générateur de sites statiques dont la conception très flexible laisse une grande liberté de choix à l'utilisateur en lui permettant de mettre simplement en place des fonctionnalités qui ne sont pas intégrées à son moteur. C'est notamment le cas lorsque l'on souhaite proposer son site en plusieurs langues : alors que les CMS sont très rigides ou nécessitent des plugins, quelques filtres suffisent pour obtenir le résultat désiré sous _Jekyll_. 

Cet article a pour objectif de présenter une façon de créer un site multilingue avec _Jekyll_. Il suppose que _Jekyll_ est bien installé et que vous savez l'utiliser pour générer un site simple.

### Objectifs
Notre site possède deux versions : anglais et en français. Sur une même page, l'intégralité du contenu (article, date, menus...) doit être dans la même langue. Un article (qu'il soit en anglais ou en français) n'a pas forcément de traduction. Les règles de typographie anglaise et française seront respectées.

Toutes les URL seront de la forme `domain.tld/nom-de-la-page/`. La racine `domain.tld` affichera la liste des articles anglais, et `domain.tld/articles/` celle des articles français. Le sélecteur de langue ne doit pas renvoyer vers la page d'accueil de l'autre version mais bien vers la traduction de la page _en cours_.



## Principe

### Arborescence des fichiers 

L'organisation de nos fichiers va être très simple. La page d'accueil `index.html`, listant les articles en version anglaise, est stockée à la racine afin d'être accessible depuis `domain.tld`. En dehors de ce fichier, l'intégralité des pages et articles (y compris la liste des articles en français) va être stockée dans `_posts/` :

```r
.  
├── index.html                       # Page d'accueil anglaise
|
└── _posts
    ├── 2014-01-01-articles.html     # Page d'accueil française
    |
    ├── 2014-03-05-hello-world.md    # Article en anglais
    └── 2014-03-05-bonjour-monde.md  # Article en français
```


### Gestion des URL

Plutôt que d'avoir des URL de la forme `/2014/03/05/bonjour-monde.html`, nous nous contenterons de simples `/bonjour-monde/`. Il suffit pour cela d'indiquer dans `_config.yml` :

```ruby
permalink: /:title/
```

### Métadonnées dans les articles

Chaque page ou article possédera une variable `lang`, qui peut valoir `en` ou `fr` selon la version de l'article. _Si une traduction existe_, la variable `trans` comportera l'adresse (depuis la racine) vers celle-ci, selon le format d'URL choisi. Les pages n'ont nullement besoin d'avoir un identifiant ou une date commune. Seule compte la variable `trans` qui indique qu'une traduction existe, et où elle se situe. 

Par exemple, un article français `_posts/2014-03-05-bonjour-monde.md` accessible à l'adresse `domain.tld/bonjour-monde/`, s'il n'a pas de traduction, comportera les métadonnées suivantes :

```ruby
---
layout: post
title:  "Bonjour monde !"
lang:   fr
---
```

S'il existe une traduction `_posts/2014-03-15-hello-world.md`, qui sera donc accessible à l'adresse `domain.tld/hello-world/`, alors les métadonnées de notre page française deviendront :

```ruby
---
layout: post
title:  "Bonjour monde !"
lang:   fr
trans:  /hello-world/
---
```

### Traduction des éléments du site
En dehors du contenu des articles, il est également nécessaire de traduire les différents éléments qui composent le site : textes des menus, du haut et du bas de page, certains titres... 

Il est possible pour cela d'enregistrer les traductions sous forme de variables dans `_config.yml`. Ainsi, `{% raw %}{{ site.t[page.lang].home }}{% endraw %}` génèrera `Accueil` ou `Home` selon la valeur de `page.lang` :

```ruby
t:
  fr:
    home:  "Accueil"
    about: "À propos"
  en:
    home:  "Home"
    about: "About"
```



## Liens entre les deux traductions

### Liste des articles par langue

Les pages affichant la liste des articles ne doivent afficher que ceux qui sont dans la bonne langue, ce qui peut être atteint facilement grâce à la métadonnée `lang`. Par exemple, pour les articles anglais :

{% raw %}

```html
<ul>
  {% for post in site.posts %}
    {% if post.lang == 'en' %}
     <li><a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endif %}
  {% endfor %}
</ul>
```

{% endraw %}


Dans le cas des articles français, il faut prendre garde de ne pas afficher la page française listant les articles. Le code précédent devient donc :

{% raw %}

```html
<ul>
  {% for post in site.posts %}
    {% if post.lang == 'fr' and post.trans != '/' %}
     <li><a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endif %}
  {% endfor %}
</ul>
```

{% endraw %}


### Afficher un lien vers la traduction de la page en cours
Pour proposer directement à un visiteur le lien vers la traduction d'un article, si elle existe, il suffit de regarder si la variable `trans` existe et, le cas échéant, sa valeur :

{% raw %}

```html
{% if page.trans %}
    <a href="{{page.trans}}">{{ site.t[page.lang].translation }}</a>
{% endif %}
```

{% endraw %}

Comme détaillé dans la partie précédente, on définit alors dans `_config.yml` :

```ruby
t:
  fr:
    translation: "read in English"
  en:
    translation: "lire en français"
```

### Sélecteur de langue
Pour créer un sélecteur de langue, comme celui présent en haut à droite de cette page, la démarche est très similaire à celle présentée au paragraphe précédent. Utiliser `!= 'fr'` plutôt que `== 'en'` permet de faire fonctionner ce sélecteur sur la page d'accueil également, où `page.lang` n'est pas défini.

{% raw %}

```html
{% if page.lang != 'fr'%}  <span class="active">en</span> | 
    {% if page.trans %}    <a href="{{page.trans}}">fr</a>
    {% else %}             <span class="inactive">fr</span>
    {% endif %}
{% else %}
    {% if page.trans %}    <a href="{{page.trans}}">en</a>
    {% else %}             <span class="inactive">en</span>
    {% endif %}          | <span class="active">fr</span>
{% endif %}
```

{% endraw %}



## Peaufinage

### Traduction des dates
À ce stade, tout peut être traduit sur le site à l'exception des dates,  générées par _Jekyll_. Les formats courts, composés uniquement de chiffres, peuvent être adaptés sans difficulté :

{% raw %}

```html
{% if page.lang == 'fr' %}
    {{ post.date | date: "%d/%m/%Y" }}
{% else %}
    {{ post.date | date: "%Y-%m-%d" }}
{% endif %}
```

{% endraw %}

En revanche, les formats longs affichent le nom des mois en anglais, indépendamment de la configuration de _Ruby_.  Le plugin `i18n-filter`, prévu pour combler cette lacune, ne traduit que le nom du mois et n'adapte pas le chiffre : _1_, _2_ ou _3_ doivent devenir _1<sup>st</sup>_, _2<sup>nd</sup>_ et _3<sup>rd</sup>_ en anglais, _1_ doit devenir _1<sup>er</sup>_ en français.

En réalité, des remplacements de chaînes suffisent. On obtient le plugin `date.rb`, à placer dans `_plugins/` :


```ruby
module Date

  def englishdate(date)
    date = date.gsub('01 ', '1<sup>th</sup> ')
    date = date.gsub('02 ', '2<sup>nd</sup> ')
    date = date.gsub('03 ', '3<sup>rd</sup> ')
    date = date.gsub('04 ', '4 ')
    date = date.gsub('05 ', '5 ')
    date = date.gsub('06 ', '6 ')
    date = date.gsub('07 ', '7 ')
    date = date.gsub('08 ', '8 ')
    date = date.gsub('09 ', '9 ')
  end

  def frenchdate(date)
    date = date.gsub('01 ', '1<sup>er</sup> ')
    date = date.gsub('02 ', '2 ')
    date = date.gsub('03 ', '3 ')
    date = date.gsub('04 ', '4 ')
    date = date.gsub('05 ', '5 ')
    date = date.gsub('06 ', '6 ')
    date = date.gsub('07 ', '7 ')
    date = date.gsub('08 ', '8 ')
    date = date.gsub('09 ', '9 ')    
    date = date.gsub('January',  'janvier')
    date = date.gsub('February', 'février')
    date = date.gsub('March',    'mars')
    date = date.gsub('April',    'avril')
    date = date.gsub('May',      'mai')
    date = date.gsub('June',     'juin')
    date = date.gsub('July',     'juillet')
    date = date.gsub('August',   'août')
    date = date.gsub('September','septembre')
    date = date.gsub('October',  'octobre')
    date = date.gsub('November', 'novembre')
    date = date.gsub('December', 'décembre')
  end
end

Liquid::Template.register_filter Date
```

La date s'affiche ainsi selon la langue :

{% raw %}

```r
{% if page.lang == 'en' %}
    {{page.date | date: "%d %B %Y" | englishdate }}
{% else %}
    {{page.date | date: "%d %B %Y" | frenchdate}}
{% endif %}
```

{% endraw %}

Il est possible d'obtenir le même résultat sans passer par un plugin grâce la syntaxe _Liquid_ ; cela est peu lisible, mais permet de compiler _Jekyll_ en mode `safe` et donc d'héberger le site sur [GitHub Pages](http://pages.github.com), où les plugins sont désactivés.

{% raw %}

```r
{{page.date | date:"%d %B %Y" | replace:'01 ','1<sup>er</sup> ' |... }}
```

{% endraw %}

### Respect des règles typographiques
Afin de respecter la typographie anglaise et d'améliorer la typographie française (et notamment améliorer le rendu des guillements ou apostrophes), il est possible d'utiliser selon les préférences [_RedCarpet_ avec _SmartyPants_](https://github.com/vmg/redcarpet), ou alors [_Kramdown_ avec _Typogruby_](https://github.com/navarroj/krampygs).

Le français possède de nombreuses règles typographiques très différentes de l'anglais :

* `!`, `?` et `;` sont précédées d'une espace fine insécable ;
* `;` et `%` sont précédées d'une espace insécable pleine ;
* les citations sont encadrées par `«` et `»` ;
* `« »` sont respectivement suivi et précédé d'une espace insécable.

L'espace fine s'obtient avec le code HTML `&thinsp;`, que l'on entoure d'un `span` doté du style `white-space:nowrap` pour lui donner un caractère insécable. L'espace insécable est obtenue avec `&nbsp;`. 

Ces remplacements pourraient être effectués à l'aide de simple remplacements de chaînes, à l'aide de `.gsub` dans un plugin ou à l'aide d'un filtre _Liquid_. Néanmoins, il faut prendre garde de ne pas effectuer de remplacements au sein des blocs de code `pre` et `code`. Le plugin `typo.rb` suivant, à placer dans `_plugins/`, offre le résultat recherché :


```ruby
class Typography < String
  def to_html
    ar = [] 
    scan(/([^<]*)(<[^>]*>)/) {
      ar << [:text, $1] if $1 != ""
      ar << [:tag, $2] }
    pre = false
    text = ""
    ar.each { |t|
      if t.first == :tag
        text << t[1]
        if t[1] =~ %r!<(/?)(?:pre|code)[\s>]!
          pre = ($1 != "/")
        end
      else
        s = t[1]
        unless pre
          thin = '<span style="white-space:nowrap">&thinsp;</span>'
          s = s.gsub('“', '«&#160;').
                gsub('”', '&#160;»').
                gsub(' ?', thin+'?').
                gsub(' !', thin+'!').
                gsub(' ;', thin+';').
                gsub(' :', '&#160;:').
                gsub(' %', '&#160;%').
                gsub(/(?<=\d)+[ ]/, '&#160;')
        end
        text << s
      end }
    text
  end
end
module Typo
  def typo(text)
    Typography.new(text).to_html
  end
end
Liquid::Template.register_filter Typo
```

On utilise ce filtre uniquement sur la version française :

{% raw %}

```r
{% if page.lang == 'fr' %}
  {{ content | typo }}
{% else %}
  {{ content }}
{% endif %}
```

{% endraw %}


## Accès au site et référencement

Les pages étant entièrement statiques, il est difficile de connaître la langue de nos visiteurs, que ce soit en détectant les entêtes envoyées par le navigateur ou en se basant sur sa localisation géographique. Néanmoins, il est possible d'améliorer le référencement en indiquant aux moteurs de recherche les pages qui constituent les traductions d'un seul et même contenu. Ainsi, les utilisateurs trouvant notre contenu par un moteur de recherche devraient se voir proposer automatiquement la bonne traduction. 

Pour ce faire, deux solutions sont possibles : [intégrer une balise `<link>`](https://support.google.com/webmasters/answer/189077?hl=fr) dans notre page, ou [l'indiquer dans un fichier `sitemaps.xml`](https://support.google.com/webmasters/answer/2620865?hl=fr).

### Avec la balise `<link>`

Il suffit d'indiquer dans la partie `<head>` chaque page, si elle possède une traduction, un lien de la forme `<link rel="alternate" hreflang="fr" href="/francais.html" ` [en faisant attention d'utiliser les bons codes de langue utilisés](https://support.google.com/webmasters/answer/189077?hl=fr). Il suffit pour cela d'utiliser le code suivant :

{% raw %}

```html
{% if page.trans %}
<link
  rel="alternate" 
  hreflang="{% if page.lang != 'fr' %}fr{% else %}en{% endif %}"
  href="{{ page.trans }}" />
{% endif %}
```

{% endraw %}

### Avec un fichier `sitemaps.xml`

Le fichier `sitemaps.xml`, qui permet aux moteurs de recherche de connaître les pages et la structure de votre site, [permet également d'indiquer aux moteurs de recherches quelles pages sont les différentes versions d'un même contenu](https://support.google.com/webmasters/answer/2620865?hl=fr).

Pour cela, il suffit d'indiquer l'intégralité des pages du site (quelle que soit leur langue) dans des éléments `<url>` et pour chacun d'entre eux l'ensemble des versions qui existent, `y compris celle que l'on est en train de décrire`. Par exemple, dans le cas de deux pages `francais.html` et `english.html` qui sont les traductions d'un même contenu, on indique :

```xml
<url>
  <loc>http://www.domain.tld/francais.html</loc>
  <xhtml:link rel="alternate" hreflang="fr"
    href="http://www.domain.tld/francais.html" />
  <xhtml:link rel="alternate" hreflang="en "
    href="http://www.domain.tld/english.html" />
</url>

<url>
  <loc>http://www.domain.tld/english.html</loc>
  <xhtml:link rel="alternate" hreflang="fr"
    href="http://www.domain.tld/francais.html" />
  <xhtml:link rel="alternate" hreflang="en "
    href="http://www.domain.tld/english.html" />
</url>
```

Ce fichier peut (bien sûr !) être généré automatiquement par Jekyll. Il suffit pour cela de créer un fichier `sitemaps.xml` à la racine du site contenant :

{% raw %}

```xml
---
---
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" 
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
  {% for post in site.posts %}
  <url>
    <loc>http://domain.tdl{{ post.url }}</loc>
    {% if post.trans %}
      <xhtml:link rel="alternate" 
                  hreflang="{{ post.lang }}" 
                  href="http://domain.tdl{{ post.url }}" />
      <xhtml:link rel="alternate" 
                  hreflang="{% if page.lang != 'fr' %}fr
                            {% else %}en{% endif %}" 
                  href="http://domain.tdl{{ post.trans }}" />
    {% endif %}
    <lastmod>{{ post.date | date_to_xmlschema }}</lastmod>
    <changefreq>weekly</changefreq>
  </url>
  {% endfor %}
</urlset>
```
{% endraw %}


*[CMS]: Système de gestion de contenu
