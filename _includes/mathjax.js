(function () {
  var script = document.createElement("script");
  script.src = "https://c328740.ssl.cf1.rackcdn.com/mathjax/latest/MathJax.js?config=TeX-AMS_HTML";
  var config = 'MathJax.Hub.Config({showMathMenu:false,messageStyle:"none",tex2jax:{inlineMath:[["$","$"]],processEscapes: true,jax:["input/TeX"]}});'+'MathJax.Hub.Startup.onload();';
  if(window.opera){script.innerHTML = config}else{script.text = config}document.getElementsByTagName("head")[0].appendChild(script);
})();

