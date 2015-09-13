---
title: Améliorer la typographie <br/> avec <em>Jekyll</em>
---

Respecter les règles de typographie sur Internet n'est pas toujours chose aisée. Bien qu'Unicode réserve de nombreuses zones de caractères pour les symboles typographiques, signes de ponctuation et espaces de différentes longueurs, leur saisie difficile sur le clavier les rend pratiquement inutilisées.

Sous *Jekyll*, les articles sont rédigés très simplement au format Markdown, avant d'être généré en HTML par le moteur : c'est à ce moment qu'il nous est possible d'ajouter des règles automatiques pour améliorer la typographie sur notre site, sans nous en préoccuper lors de la rédaction des articles.



## Typographie anglaise
De nombreuses initiatives existent pour améliorer le support de la typographie anglaise, notamment sa ponctuation. Même si votre site est rédigé dans une autre langue, il peut s'agir d'une base très utile afin de détecter les guillemets ouvrants et fermants, de convertir les guillemets ou de détecter les acronymes.

### Kramdown et Typogruby

Depuis sa version 2.0, *Jekyll* utilise par défaut[[aucune configuration particulière n'est nécessaire pour l'activer]] le moteur *Kramdown* et l'extension Typogruby, qui permet notamment :

* transforme les points de suspensions `...` en leur symbole ... ;
* de convertir les guillemets `""` en guillemets anglais “” ;
* de convertir les tirets semi-longs  `--` en -- ;
* de convertir les tirets longs  `---` en --- ;
* de détecter les acronymes et de leur appliquer une classe.


### Redcarpet et Smartypants
Avant la version 2.0, *Jekyll* utilisait par défaut le moteur *Redcarpet*. Si vous souhaitez l'utiliser avec une version postérieure, il vous suffit d'indiquer dans `_config.yml` à la racine de votre site :

```ruby
markdown: redcarpet
```

*Markdown* vient avec l'extension *SmartyPants*, qu'il vous est possible d'utiliser avec *Jekyll* bien qu'elle ne soit pas activée par défaut.
*SmartyPants* permet notamment de :

* transformer les points de suspensions `...` en leur symbole ...
* convertir les guillemets `""` en guillemets anglais “” ;
* convertir les tirets semi-longs  `--` en -- ;
* convertir les tirets longs  `---` en ---.

Pour cela, il vous suffit d'ajouter dans ce même fichier `_config.yml` :

```ruby
redcarpet:
  extensions: ['smart']
```


## Typographie française

Nous allons montrer ici comment faire en sorte que *Jekyll* génère automatiquement des guillemets français et des espaces insécables de la bonne longueur devant les divers signes de ponctuation.

### Prérequis : ne modifier que le texte

Il faut prendre garde de n'appliquer les modifications que dans les paragraphes de texte, et non au sein des blocs de code qui pourraient devenir inutilisables pour les utilisateurs qui les copieront[[les codes qui ne compileront à cause d'espaces particulières seront difficiles à débugger]].

Nous avons vu, dans l'article "[compresser le HTML produit par *Jekyll*]({{site.base}}/compresser-le-code-html-de-jekyll/)", qu'il était possible de compresser le code HTML en créant un fichier `compress.html` dans `_layout/`[[en ajoutant ensuite `layout: compress` dans l'entête des fichiers présents dans `_layout` concernés]] qui contenait :

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

Il nous suffit alors d'agir sur la variable `t`, qui correspond aux textes, en appliquant entre sa définition `{% raw %}{% assign t = temp3.last %}{% endraw %}` et son affichage  `{% raw %}{{ t | split: ' ' | join: ' ' }}{% endraw %}` différents filtres.

Par exemple, `{% raw %}{% assign t = t | replace: 'a' , 'b' %}{% endraw %}` remplacerait tous les *a* en *b* dans les textes, mais pas dans les blocs de code.

### Utiliser les guillemets français

Pour obtenir des guillemets français `«` et `»`, commençons par utiliser `SmartyPants` ou `Typogruby`[[présentés dans la partie précédente]] afin de différencier les guillemets ouvrants des guillemets sortants.

Il suffit alors de les remplacer par des guillemets français, en indiquant entre `{% raw %}{% assign t = temp3.last %}{% endraw %}` et `{% raw %}{{ t | split: ' ' | join: ' ' }}{% endraw %}`[[nous ajoutons une espace insécable normale avant le guillemet fermant, et après le guillemet entrant, avec `&#160;`]] :

```r
{% raw %}
{% assign t = t | replace: '&ldquo;' , '«&#160;' %}
{% assign t = t | replace: '&rdquo;' , '&#160;»' %}
{% endraw %}
```


### Utiliser les bonnes espaces devant la ponctuation

En français, les signes deux-points (`:`) et pourcent (`%`) doivent être précédés d'une espace insécable normale, qui s'obtient avec `&#160;`. Pour remplacer les espaces simples que vous allez taper devant[[bien que la plupart des navigateurs empêchent eux-mêmes un saut de ligne avant ces symboles]], on utilise comme précédemment :

```r
{% raw %}
{% assign t = t | replace: ' :', '&#160;:' %}
{% assign t = t | replace: ' %', '&#160;%' %}
{% endraw %}
```

En revanche, le point-virgule (`;`), le point d'exclamation (`!`) et le point  d'interrogation (`?`) sont précédés d'une espace insécable *fine*. Celle-ci s'obtient à l'aide de `&thinsp;`. Cependant, il est préférable d'utiliser `<span style="white-space:nowrap">&thinsp;</span>;` en raison de certains navigateurs qui ne traitent pas l'espace comme insécable.

On utilise alors le code suivant pour obtenir le résultat désiré :

```r
{% raw %}
{% assign t = t | replace: ' ;', '<span style="white-space:nowrap">&thinsp;</span>;' %}
{% assign t = t | replace: ' !', '<span style="white-space:nowrap">&thinsp;</span>!' %}
{% assign t = t | replace: ' ?', '<span style="white-space:nowrap">&thinsp;</span>?' %}
{% endraw %}
```


### Résultat final

Finalement, le code suivant permet d'obtenir toutes les améliorations typographiques présentées ci-dessus :

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

Si votre site est multilingue[[par exemple sur la base de l'article [Rendre *Jekyll* multilingue]({{site.base}}/rendre-jekyll-multilingue/)]], vous pouvez n'appliquer ces modifications que sur les pages françaises en plaçant, autour des parties concernées :

```r
{% raw %}
{% if page.lang == 'fr' %}
...
{% endif%}
{% endraw %}
```

