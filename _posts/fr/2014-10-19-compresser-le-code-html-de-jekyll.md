---
title: Compresser le HTML <br/> produit par <em>Jekyll</em>
---

La syntaxe *Liquid* utilisée par *Jekyll* a le désagréable défaut de générer des quantités importantes d'espaces et de sauts de ligne inutiles dans le code source de notre page. C'est particulièrement vrai lorsque l'on souhaite indenter ses codes *Liquid*, ou que l'on utilise des boucles. Ainsi, la source suivante :

```r
{% raw %}
start
{% for i in (1..3) %}
  {% assign foo = i %}
{% endfor %}
end
{% endraw %}
```

... va générer le code suivant :

```r
start
 
 
 
 
 
 
 
end
```

Ce n'est pas illogique : *Liquid* lit l'ensemble des caractères présents dans la boucle, y compris les espaces et les sauts de ligne, et les restitue sans se poser de questions.

Pour l'éviter, le plus simple est encore de compresser le code source produit, en supprimer tous les sauts de ligne et tous les espaces multiples qui ne sont pas nécessaires. 

Nous avons pour cela deux contraintes :

* ne pas compresser le contenu des balises `<pre>`, pour respecter les codes qui y sont présentés ;
* ne pas utiliser de *plugins* pour pouvoir [héberger notre site sur *GitHub Pages*](http://sylvain.durand.tf/utiliser-github-pour-servir-jekyll/).

La méthode expliquée dans cet article est librement inspirée de [`jekyll-compress-html`](https://github.com/penibelst/jekyll-compress-html), créé par [Anatol Broder](https://github.com/penibelst).

## Utilisation d'un *layout*

Nous souhaitons pouvoir modifier directement le code source de chaque page générée par Jekyll par le biais de *Liquid*.

Pour ce faire, le plus simple est de créer un fichier `compress.html` dans le dossier `layout`, puis d'ajouter au début autres *layouts*[[c'est-à-dire le ou les fichiers placés dans le dossier `layout` qui tiennent lieu de squelette]] un renvoi vers ce fichier `compress.html` dans leur entête :

```r
---
layout: compress
--- 
<html>
...
</html>
```

Dans notre fichier `compress.html`, nous pouvons ainsi agir sur l'ensemble des codes sources générés par le biais de la variable `content`. Par exemple, si l'on veut modifier la totalité des "a" par des "b", il suffit d'indiquer dans `compress.html` :

```r
{% raw %}
{{ content | replace: "a", "b" }}
{% endraw %}
```


## Détection des blocs de code
Le filtre `split` permet de découper une chaîne autour d'une sous-chaîne précise. Par exemple, le code source suivant va générer un tableau de variables dont chacune va contenir ce qui est présent entre deux `<pre>` :

```r
{% raw %}
{% assign var = content | split: '<pre>' %}
{% endraw %}
```

Il va ainsi nous être possible, à l'aide d'une boucle, d'appliquer certains filtres uniquement aux blocs de code, et d'autres au reste de la page uniquement. Ainsi, nous allons pouvoir appliquer des filtres à l'ensemble du code d'une page sans avoir d'influence sur les blocs de code[[pour ce faire, nous commençons par obtenir tous le contenu autour des `<pre>`, puis nous découpons ces parties en deux pour séparer ce qui précède le `</pre>` fermant de la suite]] en mettant dans `compress.html` :

```r
{% raw %}
{% assign temp1 = content | split: '<pre>' %}
{% for temp2 in temp1 %}
{% assign temp3 = temp2 | split: '</pre>' %}
{% if temp3.size == 2 %}
{% assign code_blocks = temp3.first %}
<pre>{{ code_blocks }}</pre>
{% endif %}
{% assign everything_else = temp3.last %}
{{ everything_else }}
{% endfor %}
{% endraw %}
```

Nous pouvons alors, sur cette base, appliquer des filtres soit uniquement aux blocs de code[[en ajoutant un filtre à `{%raw%}{{code_blocks}}{%endraw%}`]], comme par exemple rajouter des balises `<code>` à chaque ligne, ou au contraire le reste du code source du site[[en modifiant cette fois-ci `{%raw%}{{everything_else}}{%endraw%}`]], pour par exemple améliorer la typographie.

## Compression du code HTML

Il ne nous reste désormais qu'à compresser le code HTML. Nous ne voulons pas toucher au contenu des blocs de code, en revanche nous allons supprimer tous les espaces multiples et les sauts de ligne pour le reste du code. Pour cela, on utilise `split` pour chaque espace, puis `join` :

```r
{% raw %}
{{ everything_else | split: ' ' | join: ' '}}
```

On obtient donc le code suivant :

```r
{% raw %}
{% assign temp1 = content | split: '<pre>' %}
{% for temp2 in temp1 %}
{% assign temp3 = temp2 | split: '</pre>' %}
{% if temp3.size == 2 %}
{% assign code_blocks = temp3.first %}
<pre>{{ code_blocks }}</pre>
{% endif %}
{% assign everything_else = temp3.last %}
{{ everything_else | split: ' ' | join: ' '}}
{% endfor %}
{% endraw %}
```

Enfin, nous enlevons tous les sauts de lignes de ce fichier pour éviter que Jekyll n'en ajoute au moment de le traiter :

```r
{% raw %}{% assign temp1 = content | split: '<pre>' %}{% for temp2 in temp1 %}{% assign temp3 = temp2 | split: '</pre>' %}{% if temp3.size == 2 %}{% assign code_blocks = temp3.first %}<pre>{{ code_blocks }}</pre>{% endif %}{% assign everything_else = temp3.last %}{{ everything_else | split: ' ' | join: ' '}}{% endfor %}{% endraw %}
```

C'est tout ! Vous pouvez observer que le code source ne tiendra désormais qu'en une seule ligne de code, en dehors des blocs de code `<pre>` où rien n'aura été modifié.






