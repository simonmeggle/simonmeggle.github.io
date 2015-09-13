---
title: Using <em>CSS</em> to add<br/> line numbering
---

When you want to display a code listing with *HTML*, you use a `<pre>` tag in order to indicate that the text is preformatted[[and therefore the spaces and line breaks must be respected]], then inside one or multiple `<code>` tags to specify this text is a code.

On this website, the line numbers appears on the left of code listings, like most word processors. The methods to achieve this vary widely: many use *jQuery* or *Javascript*, ugly HTML codes, or even tables...

Yet it is possible to achieve this in a simple way, using only CSS and HTML. The line numbers won't be selected when the user wants to copy the code.

## HTML
The only thing to do in our HTML code is to use a `<code>` tag for each line of code. This will produce a perfectly valid HTML code, and we will number each line directly with CSS:

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

The `:before` pseudo-element will allow us to show something before each line, while the CSS counters will allow us to count the lines.

We will first define a counter that starts at one for each block, then which is incremented at each new line of code:

```css
pre{
    counter-reset: line;
}
code{
    counter-increment: line;
}
```

Then we display the number at the beginning of each line:

```css
code:before{
    content: counter(line);
}
```

With *Webkit* browsers, selecting the code to copy it gives the impression that the numbers are selected[[although fortunately they are not copied]]. To avoid this, simply use the property `user-select`:

```css
code:before{
    -webkit-user-select: none;
}
```

It only remains to improve their style as desired. That's it!

## What about *Jekyll* ?

By default, *Markdown* engine wraps code in only one `<code>` tag, instead of one tag for each line.


In the article "[compressing *Jekyll* generated HTML]({{site.base}}/compressing-jekyll-generated-html/)", we saw it is possible to compress the HTML code by creating a `compress.html` file inside `_layout/`[[then you need to add `layout: compress` into the frontmatters of the different files in `_layout`]] with the following code:

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

In order to add a `<code>` tag on each line, we just have to apply to `temp3.first` the `replace` filter in order to replace `<br/>` with `</code><br /><code>`. Then, we delete breaks with `strip_newlines`, and the last empty line. It gives us the following code:

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

