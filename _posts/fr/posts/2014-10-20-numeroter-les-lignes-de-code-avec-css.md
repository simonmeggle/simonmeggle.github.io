---
title: Numéroter les lignes <br/> de code avec <em>CSS</em>
---

Lorsque l'on souhaite afficher un bloc de lignes de code en HTML, on utilise une balise `<pre>`, pour indiquer que le texte est préformaté[[et donc en particulier que les espaces et sauts de ligne doivent être respectés]] dans laquelle on place une balise ou plusieurs balises `<code>`, pour indiquer qu'il s'agit bien de code.

Sur ce site, la numérotation des lignes apparaît à gauche de chacune d'entres elles, comme le permettent la plupart des traitements de texte. Les techniques pour obtenir ce résultat sont très variables : beaucoup utilisent *jQuery* ou *Javascript*, des codes HTML douteux, voire même des tableaux...

Pourtant, il est possible d'obtenir ce résultat de façon très simple, uniquement à l'aide de CSS et HTML, sans gêner l'utilisateur et en permettant de copier le code sans que ne se copient les nombres.

## HTML
La seule condition qui va peser sur notre HTML est d'utiliser une balise `<code>` pour chaque ligne de code. Cela produit un code HTML parfaitement valide, et nous permettra de numéroter chaque ligne directement à avec CSS :

```html
<pre>
<code>class Greeter</code>
<code>  def initialize(name)</code>
<code>    @name = name.capitalize</code>
<code>  end</code>
<code>end</code>
</pre>
```

## CSS

Le pseudo-élément `:before` va nous permettre d'afficher quelque chose avant chaque ligne, tandis que les compteurs CSS vont nous permettre de compter les lignes.

On commence par définir un compteur qui part à zéro pour chaque bloc, et qui s'incrémente à chaque ligne de code :

```css
pre{
    counter-reset: line;
}
code{
    counter-increment: line;
}
```

Ensuite, nous affichons ce nombre au début de chaque ligne :

```css
code:before{
    content: counter(line);
}
```

Sous les navigateurs *Webkit*, sélectionner le code pour le copier donne l'impression que les numéros sont sélectionnés[[même si, heureusement, ils ne seront pas copiés]]. Pour l'éviter, il suffit d'utiliser la propriété `user-select` :

```css
code:before{
    -webkit-user-select: none;
}
```

Il ne vous reste qu'à améliorer leur style à votre gré. C'est tout !

## Et avec *Jekyll* ?

Par défaut, le moteur *Markdown* de *Jekyll* ne place qu'un seul élément `<code>` dans les balises `<pre>`, alors qu'il nous en faudrait un pour chaque ligne.

Nous avons vu, dans l'article "[compresser le HTML produit par *Jekyll*]({{site.base}}/compresser-le-code-html-de-jekyll/)", qu'il était possible de compresser notre code HTML en créant un fichier `compress.html` dans `_layout/`[[en ajoutant ensuite `layout: compress` dans l'entête des fichiers présents dans `_layout` concernés]] qui contenait :

```r
{% raw %}
{% capture compress %}
{% assign temp1 = content | split: '<pre>' %}
{% for temp2 in temp1 %}
{% assign temp3 = temp2 | split: '</pre>' %}
{% if temp3.size == 2 %}
<pre>{{ temp3.first | newline_to_br }}</pre>
{% endif %}
{{ temp3.last | split: ' ' | join: ' ' }}
{% endfor %}
{% endcapture %}{{ compress | strip_newlines }}
{% endraw %}
```

Pour ajouter une balise `<code>` pour chaque ligne, il suffit d'appliquer à `temp3.first` le filtre `replace` pour remplacer les `<br/>`par `</code><br /><code>`. On supprime ensuite les sauts de ligne avec `strip_newlines`, et enfin on supprime la dernière ligne vide qui subsiste. On obtient alors le code suivant :

```r
{% raw %}
{% capture compress %}
{% assign temp1 = content | split: '<pre>' %}
{% for temp2 in temp1 %}
{% assign temp3 = temp2 | split: '</pre>' %}
{% if temp3.size == 2 %}
<pre>{{ temp3.first | newline_to_br | replace: "<br />", "</code><br /><code>" | strip_newlines | replace: "<code></code>", ""}}</pre>
{% endif %}
{{ temp3.last | split: ' ' | join: ' ' }}
{% endfor %}
{% endcapture %}{{ compress | strip_newlines }}
{% endraw %}
```



