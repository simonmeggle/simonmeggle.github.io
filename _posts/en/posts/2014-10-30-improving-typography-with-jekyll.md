---
title: Improving typography <br/> with <em>Jekyll</em>
---

Observing typographical rules on the Internet is not always easy. Although Unicode reserves many areas of characters for typographic symbols, many punctuation marks and spaces are most of the time unused.

With *Jekyll*, the articles are written very simply with Markdown before being generated in HTML by the engine: we can add automatic rules to improve typography on our site without carrying about it when writing articles.


## English typography
Many initiatives exist for improving the support of the English typography, including its punctuation. Even if your site is written in another language, it can be a very useful basis to detect the opening and closing quotes, convert quotes or detect acronyms.

### Kramdown and Typogruby

Since version 2.0, *Jekyll* use by default[[no special configuration is required to enable it]] *Kramdown* engine and Typogruby extension, which:

* transforms the ellipsis `...` in its symbol... ;
* convert quotation marks `""` in English quotation marks “” ;
* convert semi-long dashes  `--` in -- ;
* convert long dashes  `---` in --- ;
* detect acronyms and apply them a class.


### Redcarpet and Smartypants
Before version 2.0, *Jekyll* used *Redcarpet* as a default engine. If you want to use it with a later version, simply indicate in `_config.yml` to the root of your site:

```ruby
markdown: redcarpet
```

*Markdown* comes with the extension *SmartyPants*, which you can use with *Jekyll* although it is not enabled by default. *SmartyPants* notably allows to:

* transforms the ellipsis `...` in its symbol... ;
* convert quotation marks `""` in English quotation marks “” ;
* convert semi-long dashes  `--` in -- ;
* convert long dashes  `---` in ---.

To do this, simply add in the same `_config.yml` file:

```ruby
redcarpet:
  extensions: ['smart']
```


## French typography

We will show here how to make *Jekyll* automatically generates quotes French and non-breaking spaces to the right length before the various punctuation marks.

### Prerequisite: modify texts only

Care must be taken to apply the changes only in paragraphs, not in code blocks that could become unusable for users that will copy them.

We have seen, in the article "[compressing *Jekyll* generated HTML]({{site.base}}/compressing-jekyll-generated-html/)", it is possible to compress HTML by creating a `compress.html` file in `_layout/`[[then, you need to add `layout: compress` in the layout files headers]] which contains:

```r
{% raw %}
{% capture compress %}
{% assign temp1 = content | split: '<pre>' %}
{% for temp2 in temp1 %}
{% assign temp3 = temp2 | split: '</pre>' %}
{% if temp3.size == 2 %}
<pre>{{ temp3.first | newline_to_br }}</pre>
{% endif %}
{% assign t = temp3.last %}
{{ t | split: ' ' | join: ' ' }}
{% endfor %}
{% endcapture %}{{ compress | strip_newlines }}
{% endraw %}
```

We just have to act on the variable `t`, which corresponds to the texts, by applying between its definition `{% raw %}{% assign t = temp3.last %}{% endraw %}` and its display  `{% raw %}{{ t | split: ' ' | join: ' ' }}{% endraw %}` different filters.

For example, `{% raw %}{% assign t = t | replace: 'a' , 'b' %}{% endraw %}` would replace all *a*'s in *b*'s in the texts, but not in the code blocks.

### Using French guillemets

For quotes French `«` et `»`, let's start by using `SmartyPants` or `Typogruby`[[presented in the previous section]] to differentiate the opening quotation marks outgoing quotes.

Then simply replace them with French quotation marks, indicating between `{% raw %}{% assign t = temp3.last %}{% endraw %}` and `{% raw %}{{ t | split: ' ' | join: ' ' }}{% endraw %}`[[we add a normal non-breaking space before the closing quotation mark, and after entering quote with `&#160;`]] :

```r
{% raw %}
{% assign t = t | replace: '&ldquo;' , '«&#160;' %}
{% assign t = t | replace: '&rdquo;' , '&#160;»' %}
{% endraw %}
```


### Using the right spaces before punctuation

In French, the colons (`:`) and percent (`%`) must be preceded by a normal non-breaking space, which is obtained with `&#160;`. We use:

```r
{% raw %}
{% assign t = t | replace: ' :', '&#160;:' %}
{% assign t = t | replace: ' %', '&#160;%' %}
{% endraw %}
```

However, the semicolon(`;`), the exclamation point (`!`) and the question mark (`?`) are preceded by a *thin* non-breaking space. Thereof is obtained using `&thinsp;`. However, it is preferable to use `<span style="white-space:nowrap">&thinsp;</span>;` because some browsers that do not treat the space as indivisible.

We then use the following code to get the desired result:

```r
{% raw %}
{% assign t = t | replace: ' ;', '<span style="white-space:nowrap">&thinsp;</span>;' %}
{% assign t = t | replace: ' !', '<span style="white-space:nowrap">&thinsp;</span>!' %}
{% assign t = t | replace: ' ?', '<span style="white-space:nowrap">&thinsp;</span>?' %}
{% endraw %}
```


### Final result

Finally, the following code provides all the typographical improvements presented above:

```r
{% raw %}
{% capture compress %}
{% assign temp1 = content | split: '<pre>' %}
{% for temp2 in temp1 %}
{% assign temp3 = temp2 | split: '</pre>' %}
{% if temp3.size == 2 %}
<pre>{{ temp3.first | newline_to_br }}</pre>
{% endif %}
{% assign t = temp3.last %}
{% assign t = t | replace: '&ldquo;' , '«&#160;' %}
{% assign t = t | replace: '&rdquo;' , '&#160;»' %}
{% assign t = t | replace: ' :',       '&#160;:' %}
{% assign t = t | replace: ' %',       '&#160;%' %}
{% assign t = t | replace: ' ;', '<span style="white-space:nowrap">&thinsp;</span>;' %}
{% assign t = t | replace: ' !', '<span style="white-space:nowrap">&thinsp;</span>!' %}
{% assign t = t | replace: ' ?', '<span style="white-space:nowrap">&thinsp;</span>?' %}
{{ t | split: ' ' | join: ' ' }}
{% endfor %}
{% endcapture %}{{ compress | strip_newlines }}
{% endraw %}
```

If your website is multilingual[[as explained, for example, in the article [Making *Jekyll* multilingual]({{site.base}}/making-jekyll-multilingual/)]], you can restrict the previous modifications to the French articles, by adding around:

```r
{% raw %}
{% if page.lang == 'fr' %}
...
{% endif%}
{% endraw %}
```

