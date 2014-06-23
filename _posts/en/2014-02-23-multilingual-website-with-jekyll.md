---
title:  Multilingual website with <em>Jekyll</em>
trans: /site-multilingue-avec-jekyll/
---

J _ekyll_ static website generator has a very flexible design that allows a great freedom of choice, allowing the user to simply introduce features that are not integrated into its engine. This is particularly the case when one wants to create a multilingual website: while CMS remain very rigid and often require plugins, few filters are sufficient to achieve it with _Jekyll_.

This article aims to present a way to create a multilingual site with _Jekyll_. _Jekyll_ have to be installed on your computer and you should be able to know how to generate a simple website.

### Goals
Our site has two versions: English and French. On the same page, the entire contents (article, date, menus ...) must be in the same language, but an article (whether in English or French) is not necessarily translated. The rules of English and French typography will be respected.

All URL will be like `domain.tld/article-name/`. `domain.tld` root will display the list of English articles, and `domain.tld/articles/` the list of French articles. The language selector (on the top right) musn't lead to the translated homepage but to the translation of the _current_ page.

Everything will work without any plugin, in order to generate the site in `safe` mode and thus to be able to host it on [GitHub Pages](https://pages.github.com/).


## Principle

### File tree 


The organization of our files will be very simple. Home page `index.html`, listing articles in English, is stored at the root to be accessible from `domain.tld`. All other pages and articles (including the list of articles in French) will be stored in `_posts /`:

{% highlight r %}
.  
├── index.html                        # English home page
|
└── _posts
    ├── 2014-01-01-articles.html      # French home page
    |
    ├── 2014-03-05-hello-world.md     # English article
    └── 2014-03-05-bonjour-monde.md   # French article
{% endhighlight %}


### Prettier URL

Instead of having URL like `/2014/03/05/hello-world.html`, we only want the prettier `/hello-world/`. Simply indicate in `_config.yml`:


{% highlight ruby %}
permalink: /:title/
{% endhighlight %}


### Articles metadata

Each page or article will have a variable `lang`, which can be worth `en` or `fr` depending on the lang of the article. _If a translation exists_, `trans` will be the address (from the root) to it, as the URL format previously selected. The pages have no need to have an identifier or a common date. Account only the variable `trans` indicating that translation exists, and where it is located.

For instance, a French article `_posts/2014-03-05-bonjour-monde.md` available at `domain.tld/bonjour-monde/`, if there is no translation, include the following metadata:

{% highlight ruby %}
---
layout: post
title:  "Bonjour monde !"
lang:   fr
---
{% endhighlight %}

If a translation `_posts/2014-03-15-hello-world.md` exists, which will be accessible at `domain.tld/hello-world/`, then the metadata our French page become:

{% highlight ruby %}
---
layout: post
title:  "Bonjour monde !"
lang:   fr
trans:  /hello-world/
---
{% endhighlight %}

### Translation of website elements 
Outside the content of the articles, it is also necessary to translate the various elements like menus, header, footer, some titles... 

It is possible to save translation as variables in `_config.yml`. Then, `{% raw %}{{ site.t[page.lang].home }}{% endraw %}` will generate `Accueil` or `Home` depending `page.lang` value:

{% highlight ruby %}
t:
  fr:
    home:  "Accueil"
    about: "À propos"
  en:
    home:  "Home"
    about: "About"
{% endhighlight %}



## Links between the two translations 

### List of articles

The home page will display a list of articles depending of their language, which can be reached easily with the metadata `lang`. For example, for English items:

{% highlight html %}
{% raw %}
<ul>
  {% for post in site.posts %}
    {% if post.lang == 'en' %}
     <li><a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endif %}
  {% endfor %}
</ul>
{% endraw %}
{% endhighlight %}

In the case of French articles, we musn't display the french homepage. The previous code becomes:

{% highlight html %}
{% raw %}
<ul>
  {% for post in site.posts %}
    {% if post.lang == 'fr' and post.trans != '/' %}
     <li><a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endif %}
  {% endfor %}
</ul>
{% endraw %}
{% endhighlight %}

### Display a link to the translation of the current page 
To offer the visitor directly to a link to the translation of an article if it exists, just look if the variable `trans` exists and its value:

{% highlight html %}
{% raw %}
{% if page.trans %}
    <a href="{{page.trans}}">{{ site.t[page.lang].translation }}</a>
{% endif %}
{% endraw %}
{% endhighlight %}

As explain in the previous section, we define in `_config.yml`:

{% highlight ruby %}
t:
  fr:
    translation: "read in English"
  en:
    translation: "lire en français"
{% endhighlight %}

### Sélecteur de langue
To create a language selector, like this at the top right of this page, the process is very similar to that presented in the previous paragraph. We use `!= 'fr'` instead of `== 'en'` in order to make this selector working on the homepage, where `page.lang` is not defined.

{% highlight html %}
{% raw %}
{% if page.lang != 'fr'%}  <span class="active">en</span> | 
    {% if page.trans %}    <a href="{{page.trans}}">fr</a>
    {% else %}             <span class="inactive">fr</span>
    {% endif %}
{% else %}
    {% if page.trans %}    <a href="{{page.trans}}">en</a>
    {% else %}             <span class="inactive">en</span>
    {% endif %}          | <span class="active">fr</span>
{% endif %}
{% endraw %}
{% endhighlight %}


## Tweaking

### Translation of dates 
At this point, everything can be translated on the site except the dates automatically generated by _Jekyll_. Short formats, consisting only of numbers, can be adapted without difficulty:

{% highlight html %}
{% raw %}
{% if page.lang == 'fr' %}
    {{ post.date | date: "%d/%m/%Y" }}
{% else %}
    {{ post.date | date: "%Y-%m-%d" }}
{% endif %}
{% endraw %}
{% endhighlight %}

For long dates, it is possible to use date filters and replacements for any format. For example, in order to translate the date in English and in French, you can use:

{% highlight html %}
{% raw %}
{% assign d = page.date | date: "%-d" %}
{% assign m = page.date | date: "%-m" %}

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

{% else %}

{{ d }}<sup>{% case d %}
  {% when '1' or '21' or '31' %}st
  {% when '2' or '22' %}nd
  {% when '3' or '23' %}rd
{% else %}th
{% endcase %}</sup> 
{{ page.date | date: "%B %Y"}}

{% endif %}
{% endraw %}
{% endhighlight %}




### Typographic rules

Since Jekyll 2, Kramdown rendering engine is used by default and improves the rendering of apostrophes, quotes and long dashes. In order to use French quotes instead of double quotes, simply replace the string: 
{% highlight html %}
{% raw %}
{% if lang == 'en' %}
  {{ content }}
{% else %}
  {{ content | replace: '“', '«&#160;' | replace: '”', '&#160;»' }}
{% endif %}
{% endraw %}
{% endhighlight %}

## Website access and search engine

The website is completely static, so it is difficult to know the language of our visitors, either by detecting the headers sent by the browser or on the basis of their geographical location. Nevertheless, it is possible to indicating the search engines which pages are translations of the same content. Thus, search engine should be automatically suggest the correct translation to our visitors.

To do so, two ways are possible: [use `<link>`](https://support.google.com/webmasters/answer/189077?hl=en) or [create a `sitemaps.xml` file](https://support.google.com/webmasters/answer/2620865?hl=en).

### With a &lt;link&gt; tag

You only have to provide, in each translated page, a link like `<link rel="alternate" hreflang="fr" href="/francais.html" `. [Be careful about the country codes](https://support.google.com/webmasters/answer/189077?hl=en). Use the following Liquid code:

{% highlight html %}
{% raw %}
{% if page.trans %}
<link
  rel="alternate" 
  hreflang="{% if page.lang != 'fr' %}fr{% else %}en{% endif %}"
  href="{{ page.trans }}" />
{% endif %}
{% endraw %}
{% endhighlight %}

### With a sitemaps.xml file

The `sitemaps.xml` file,  which allows search engines to know the pages and the structure of your website, [also helps tell the search engines which pages are different translations of the same content](https://support.google.com/webmasters/answer/2620865?hl=en).

For this, just indicate all pages of the site (regardless of language) in `<url>` elements, and for each of them all the versions that exist, including the one _we are now describing_. For example, in the case of two pages `francais.html` and `english.html` that are translations of the same content, we should provide:

{% highlight xml %}
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
{% endhighlight %}

This file can (of course!) be automatically generated by Jekyll. Simply create a file `sitemaps.xml` to the root, containing:

{% highlight xml %}
{% raw %}
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
{% endraw %}
{% endhighlight %}


*[CMS]: Content management system
