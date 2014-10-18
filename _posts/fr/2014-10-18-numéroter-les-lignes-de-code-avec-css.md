---
title: Numéroter les lignes <br/> de code avec <em>CSS</em>
---

Lorsque l'on souhaite afficher un bloc de lignes de code en HTML, on utilise une balise `<pre>`, pour indiquer que le texte est préformaté[[et donc en particulier que les espaces et sauts de ligne doivent être respectés]] dans laquelle on place une balise ou plusieurs balises `<code>`, pour indiquer qu'il s'agit bien de code. 

Sur ce site, la numérotation des lignes apparaît à gauche de chacune d'entres elles, comme le permettent la plupart des traitements de texte. Par exemple :

```ruby
class Greeter
  def initialize(name)
    @name = name.capitalize
  end
  def salute
    puts "Hello #{@name}!"
  end
end

g = Greeter.new("world")
g.salute
```

Sur Internet, les techniques pour obtenir ce résultat sont très variables : beaucoup utilisent *jQuery* ou *Javascript*, des codes HTML peu catholiques, voire même des tableaux...

Pourtant, il est possible d'obtenir ce résultat de façon très simple, uniquement à l'aide de CSS et HTML, sans gêner l'utilisateur et en permettant de copier le code sans que ne se copie les nombres.

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

Nous verrons dans un futur article comment compresser le code HTML avec *Jekyll*, tout en générant des balises `<code>` à chaque ligne, nous permettant donc de les numéroter.

