---
layout: post
title:  Generate a multilingual website with <em>Jekyll</em>
trans: /site-multilingue-avec-jekyll/
---

J _ekyll_ static website generator has a very flexible design that allows a great freedom of choice, allowing the user to simply introduce features that are not integrated into its engine. This is particularly the case when one wants to create a multilingual website: while CMS remain very rigid and often require plugins, few filters are sufficient to achieve it with _Jekyll_.

This article aims to present a way to create a multilingual site with _Jekyll_. _Jekyll_ have to be installed on your computer and you should be able to know how to generate a simple website.

### Goals
Our site has two versions: English and French. On the same page, the entire contents (article, date, menus ...) must be in the same language, but an article (whether in English or French) is not necessarily translated. The rules of English and French typography will be respected.

All URL will be like `domain.tld/article-name/`. `domain.tld` root will display the list of English articles, and `domain.tld/articles/` the list of French articles. The language selector (on the top right) musn't lead to the translated homepage but to the translation of the _current_ page.


## Principle

### File tree 


The organization of our files will be very simple. Home page `index.html`, listing articles in English, is stored at the root to be accessible from `domain.tld`. All other pages and articles (including the list of articles in French) will be stored in `_posts /`:

```r
.  
├── index.html                        # English home page
|
└── _posts
    ├── 2014-01-01-articles.html      # French home page
    |
    ├── 2014-03-05-hello-world.md     # English article
    └── 2014-03-05-bonjour-monde.md   # French article
```


### Prettier URL

Instead of having URL like `/2014/03/05/hello-world.html`, we only want the prettier `/hello-world/`. Simply indicate in `_config.yml`:


```ruby
permalink: /:title/
```


### Articles metadata

Each page or article will have a variable `lang`, which can be worth `en` or `fr` depending on the lang of the article. _If a translation exists_, `trans` will be the address (from the root) to it, as the URL format previously selected. The pages have no need to have an identifier or a common date. Account only the variable `trans` indicating that translation exists, and where it is located.

For instance, a French article `_posts/2014-03-05-bonjour-monde.md` available at `domain.tld/bonjour-monde/`, if there is no translation, include the following metadata:

```ruby
---
layout: post
title:  "Bonjour monde !"
lang:   fr
---
```

If a translation `_posts/2014-03-15-hello-world.md` exists, which will be accessible at `domain.tld/hello-world/`, then the metadata our French page become:

```ruby
---
layout: post
title:  "Bonjour monde !"
lang:   fr
trans:  /hello-world/
---
```

### Translation of website elements 
Outside the content of the articles, it is also necessary to translate the various elements like menus, header, footer, some titles... 

It is possible to save translation as variables in `_config.yml`. Then, `{% raw %}{{ site.t[page.lang].home }}{% endraw %}` will generate `Accueil` or `Home` depending `page.lang` value:

```ruby
t:
  fr:
    home:  "Accueil"
    about: "À propos"
  en:
    home:  "Home"
    about: "About"
```



## Links between the two translations 

### List of articles

The home page will display a list of articles depending of their language, which can be reached easily with the metadata `lang`. For example, for English items:

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


In the case of French articles, we musn't display the french homepage. The previous code becomes:

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


### Display a link to the translation of the current page 
To offer the visitor directly to a link to the translation of an article if it exists, just look if the variable `trans` exists and its value:

{% raw %}

```html
{% if page.trans %}
    <a href="{{page.trans}}">{{ site.t[page.lang].translation }}</a>
{% endif %}
```

{% endraw %}

As explain in the previous section, we define in `_config.yml`:

```ruby
t:
  fr:
    translation: "read in English"
  en:
    translation: "lire en français"
```

### Sélecteur de langue
To create a language selector, like this at the top right of this page, the process is very similar to that presented in the previous paragraph. We use `!= 'fr'` instead of `== 'en'` in order to make this selector working on the homepage, where `page.lang` is not defined.

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


## Tweaking

### Translation of dates 
At this point, everything can be translated on the site except the dates generated by _Jekyll_. Short formats, consisting only of numbers, can be adapted without difficulty:

{% raw %}

```html
{% if page.lang == 'fr' %}
    {{ post.date | date: "%d/%m/%Y" }}
{% else %}
    {{ post.date | date: "%Y-%m-%d" }}
{% endif %}
```

{% endraw %}

However, long formats display English months,regardless of Ruby configuration.  `i18n-filter` plugin only translates the Month, but doesn't fit to the figures: _1_, _2_ ou _3_ should become _1<sup>st</sup>_, _2<sup>nd</sup>_ et _3<sup>rd</sup>_ in English, and _1_ should be _1<sup>er</sup>_ in French.

In fact, strings replacements are enough. It gives us the following `date.rb` plugin, located in `_plugins/`:


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

We choose the format depending of the lang:

{% raw %}

```r
{% if page.lang == 'en' %}
    {{page.date | date: "%d %B %Y" | englishdate }}
{% else %}
    {{page.date | date: "%d %B %Y" | frenchdate}}
{% endif %}
```

{% endraw %}

We could get the same result without a plugin thanks to _Liquid_ filters:

{% raw %}

```r
{{page.date | date:"%d %B %Y" | replace:'01 ','1<sup>er</sup> ' |... }}
```

{% endraw %}

### Typographic rules

In order to improve both English and French typography, you may use [_RedCarpet_ with _SmartyPants_](https://github.com/vmg/redcarpet), or [_Kramdown_ with _Typogruby_](https://github.com/navarroj/krampygs).

The French language has many different typographic rules of English:

* `!`, `?` and `;` are preceded by a thin non-breaking space;
* `;` and `%` are preceded by a full non-breaking space;
* quotes are surrounded by `«` and `»`;
* `« »` are respectively followed and preceded by a non-breaking space.

The thin space is given by `&thinsp;`, surrounded with a `span` with the style `white-space:nowrap` in order to make him non-breaking. The non-breaking space is obtained with `&nbsp;`. 

These substitutions may be made ​​using simple replacements chains, using `.gsub` with _Liquid_ filters. However, we must take care not to make substitutions in blocks of code `pre` et `code`. The following plugin `typo.rb` provides the desired result:



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

We use this filter only on the French version:

{% raw %}

```r
{% if page.lang == 'fr' %}
  {{ content | typo }}
{% else %}
  {{ content }}
{% endif %}
```

{% endraw %}


## Website access and search engine

Les pages étant entièrement statiques, il est difficile de connaître la langue de nos visiteurs, que ce soit en détectant les entêtes envoyées par le navigateur ou en se basant sur sa localisation géographique. Néanmoins, il est possible d'améliorer le référencement en indiquant aux moteurs de recherche les pages qui constituent les traductions d'un seul et même contenu. Ainsi, les utilisateurs trouvant notre contenu par un moteur de recherche devraient se voir proposer automatiquement la bonne traduction. 

The website is completely static, so it is difficult to know the language of our visitors, either by detecting the headers sent by the browser or on the basis of their geographical location. Nevertheless, it is possible to indicating the search engines which pages are translations of the same content. Thus, search engine should be automatically suggest the correct translation to our visitors.

To do so, two ways are possible: [use `<link>`](https://support.google.com/webmasters/answer/189077?hl=en) or [create a `sitemaps.xml` file](https://support.google.com/webmasters/answer/2620865?hl=en).

### With a &lt;link&gt; tag

You only have to provide, in each translated page, a link like `<link rel="alternate" hreflang="fr" href="/francais.html" `. [Be careful about the country codes](https://support.google.com/webmasters/answer/189077?hl=en). Use the following Liquid code:
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

### With a sitemaps.xml file

The `sitemaps.xml` file,  which allows search engines to know the pages and the structure of your website, [also helps tell the search engines which pages are different translations of the same content](https://support.google.com/webmasters/answer/2620865?hl=en).

For this, just indicate all pages of the site (regardless of language) in `<url>` elements, and for each of them all the versions that exist, including the one _we are now describing_. For example, in the case of two pages `francais.html` and `english.html` that are translations of the same content, we should provide:

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

This file can (of course!) be automatically generated by Jekyll. Simply create a file `sitemaps.xml` to the root, containing:

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


*[CMS]: Content management system
