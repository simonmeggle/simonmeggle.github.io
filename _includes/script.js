{% capture js %}

(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

ga('create', 'UA-54201871-1', 'auto');
ga('require', 'displayfeatures');
ga('send', 'pageview');

{% if page.content contains "[^" %}

var $ = function(el){return document.querySelectorAll(el);};

function marginalia(){
  if(window.innerWidth > 1000){
    $('body')[0].className="marginalia";
    var nodes = $('.marginalia ol li'); var end = 0;
    for(var i=0;i<nodes.length;i++){
      position=$('[href="#'+nodes[i].getAttribute('id')+'"]')[0].getBoundingClientRect().top + window.pageYOffset;
      if(position<end){position=end}
      nodes[i].style.top = position+'px';
      var end = position+nodes[i].clientHeight+30;}}
  else{ $('body')[0].className=""}}

document.addEventListener('DOMContentLoaded', function(){marginalia();});
window.onresize = function(event){marginalia();};
window.onload = function(event){marginalia();};

{% endif %}
{% if page.content contains "$$" %}

(function () {
  var script = document.createElement("script");
  script.src = "https://c328740.ssl.cf1.rackcdn.com/mathjax/latest/MathJax.js?config=TeX-AMS_HTML";
  var config = 'MathJax.Hub.Config({showMathMenu:false,messageStyle:"none",tex2jax:{inlineMath:[["$","$"]],processEscapes: true,jax:["input/TeX"]}});'+'MathJax.Hub.Startup.onload();';
  if(window.opera){
    script.innerHTML = config}
  else{
    script.text = config}

  document.getElementsByTagName("head")[0].appendChild(script); })();

{% endif %}

{% endcapture %}{{ js | strip_newlines | remove: '  ' }}