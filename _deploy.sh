
# Compilation de Jekyll
jekyll build

# Optimisation et ompression de tous les fichiers
find _site -name '*.jpg' -exec jpegoptim --strip-all -m80 {} \;
find _site -name '*.png' -exec optipng -o5 {} \;
find _site -path _site/static -prune -o -type f -exec gzip -n "{}" \; -exec mv "{}.gz" "{}" \;



# Synchronisation des médias
s3cmd  --acl-public --cf-invalidate --cf-invalidate-default-index -M --add-header="Cache-Control: max-age=6048000" sync _site/static s3://sylvain.durand.tf/ 

# Synchronisation des autres fichiers
s3cmd --acl-public --cf-invalidate --cf-invalidate-default-index -M  -m text/html --add-header 'Content-Encoding:gzip' --add-header="Cache-Control: max-age=604800" --exclude="/static/*" sync _site/ s3://sylvain.durand.tf/ 

# Suppression des fichiers retirés en local
s3cmd --delete-removed --cf-invalidate-default-index sync _site/ s3://sylvain.durand.tf/ 
