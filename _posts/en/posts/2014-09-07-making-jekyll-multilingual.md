---
title: Making <em>Jekyll</em> <br/> multilingual
redirect_from: /multilingual-website-with-jekyll/
---

J<em>ekyll</em> has a very flexible design that allows a great freedom of choice, allowing the user to simply introduce features that are not integrated into its engine. This is particularly the case when one wants to create a multilingual website: while CMS remain very rigid and often require plugins, few filters are sufficient to achieve it with _Jekyll_.

This article aims to present a way to create a multilingual site with _Jekyll_. _Jekyll_ have to be installed[[the article [Static website with *Jekyll*]({{site.base}}/static-website-with-jekyll/) explains how to install and use *Jekyll* in order to get a simple website]] on your computer and you should be able to know how to generate a simple website.

### Goals
Our website can be translated in as many languages as wanted. In the following examples, it will have three languages: English, French, and Chinese. Each page may be translated or not in the various languages[[regardless of the version, they may be pages which are not translated in each language]]. On each page, the entire contents --- article, date, menus, URL --- must be in the same language.

A language selector, as the one on the top right of this website, will show the actual language and the different translations available[[the selector musn't lead to the translated homepage, but to the translation of the current page]].

Everything will work without any plugin, in order to get a good compatibility with the future versions of *Jekyll* and to be able to generate the site in `safe` mode and thus to be able to host it on [GitHub Pages](https://pages.github.com/).


## Principle

### File tree

Every article will be put in the `_posts` folder on the root of the website. In this folder, we will create one folder for each language, in order to stay organized and to declare the language of the articles[[it is quite possible to organized differently the articles, but you may have to provide manually the language in each frontmatter]]:

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

In this folder, you can freely organise your files. The only rule is to name each post with the publication date, followed by its identifier.

We will then declare the `lang` variable for each folder[[it is also possible to provide manually the lang in the frontmatters]], in order to be able later to detect the lang and the translations. To do so, we write the following statement in `_config.yml`:

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

### URL format

By default, *Jekyll* generates URL from the filenames, with the following format: `/2014/09/01/hello-world.html`. As it is done on this website, it is possible[[*Jekyll* [documentation](http://jekyllrb.com/docs/permalinks/) explains the various possibilities]] to show only `/hello-world/` by writing in `_config.yml`:

```ruby
permalink: /:title/
```

It is also possible to specify an URL for each file, by using the `permalink` variable in the frontmatter[[for instance, you need to provide `permalink: /` on the homepage]].

### Giving an identifier to each article

Until now, nothing links the various version of a same page. To do so, we could use:

 - *the date*, but several different articles may have the same or, on the contrary, several translations of the same article may have differents dates;
 - *the filename*, but it is quite better to translate those in order to get translated URL.

This is why the most simple way is to give an unique *identifier* to each article, shared between each translation:

```python
---
title: Hello World!
name: hello
---
```


## Links between the two translations

### List of articles

The page listing the articles has to display only the one with the good translation. That is easy to do, thanks to the `lang` metadata. The following code provides every article with the same language than the actual page:

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

If you don't want to show some pages in the list, you just have to provide "`type: pages`" in their frontmatter, and to add in `assign` the condition "`| where:"type", "posts"`".

### Language selector

To create a language selector, like the one at the top right of this page, the process is very similar. We show the language of each translation available, including the actual page, sorting by path in order to always get the same order:

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

Then, in order to emphase the actual version, just use CSS[[you need to declare the `lang` attribute on the `html`, with `<html lang="{{ page.lang }}">` in the *layout*]]. For instance, if you want to bold it:

```css
.en:lang(en), .fr:lang(fr), .zh:lang(zh){
    font-weight: bold;
}
```

## Tweaking

### Translation of website elements
Around the articles, it is also necessary to translate the various elements like menus, header, footer, some titles...

To do so, we can provide translations into `_config.yml`[[since *Jekyll* 2.0, it is also possible to put the translations in the [_data](http://jekyllrb.com/docs/datafiles/) folder]]. Then, in the following example, `{% raw %}{{site.t[page.lang].home}}{% endraw %}` will generate `Home`, `Accueil` or `首页` depending of the page language:

```python
t:
  en:
    home:  "Home"
  fr:
    home:  "Accueil"
  zh:
    home:  "首页"
```

It is possible to do the same in order to generate the menu of each version. For example, if you want to provide a two elements menu, you just have to provide in `_config.yml` :

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

Then, you can generate the menu with a simple loop:

```html
{% raw %}
<ul>
  {% for menu in site.t[page.lang] %}
    <li><a href="{{menu[1].url}}">{{menu[1].title}}</a></li>
  {% endfor %}
</ul>
{% endraw %}
```

### Translation of dates
At this point, everything can be translated on the site except the dates automatically generated by *Jekyll*. Short formats, consisting only of numbers, can be adapted without difficulty. Depending of the language, we want to get:

- in English : "2014/09/01" ;
- in French : "01/09/2014" ;
- in Chinese : "2014年9月1号".

To do so, we just have to use the following code, which we may then put in the `_includes` folder in order to use it when needed:

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

For the long format dates, it is possible to use date filters and replacements for any format. For example, we want to get:

- in English : "1<sup>st</sup> of September 2014" ;
- in French : "1<sup>er</sup> septembre 2014".

We just have to use the following code:

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

Again, it is possible to put this code in a file named `date.html` stored in the `_includes` folder, in order to call it without having to duplicate it.

## Website access and search engine

The website is completely static, so it is difficult to know the language of our visitors, either by detecting the headers sent by the browser or on the basis of their geographical location. Nevertheless, it is possible to indicating the search engines which pages are translations of the same content[[thus, users finding our website through a search engine should be offered the good translation]].

To do so, two ways are possible: [use `<link>`](https://support.google.com/webmasters/answer/189077?hl=en) or [create a `sitemaps.xml` file](https://support.google.com/webmasters/answer/2620865?hl=en).

### With a *link* tag

You only have to provide in the `<head>` part of the page, every translation available of the actual version[[you need to be careful to use the good [country codes](https://support.google.com/webmasters/answer/189077?hl=en)]]. To do so, we can use the following code, similar to those used previously:

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

### With a *sitemaps* file

The `sitemaps.xml` file,  which allows search engines to know the pages and the structure of your website, [also helps tell the search engines which pages are different translations of the same content](https://support.google.com/webmasters/answer/189077?hl=en).

For this, just indicate all pages of the site (regardless of language) in `<url>` elements, and for each of them all the versions that exist, including the one we are now describing.

This file can be generated automatically by *Jekyll* with the following code, which will create a `sitemaps.xml` file on the root of the website:

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
