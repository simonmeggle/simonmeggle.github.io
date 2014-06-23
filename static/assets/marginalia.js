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
window.onresize = function(event){marginalia();}
window.onload = function(event){marginalia();}