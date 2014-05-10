# Build Jekyll
jekyll build

# Compressing and optimizing files
find _site -name '*.jpg' -exec jpegoptim --strip-all -m80 {} \;
find _site -name '*.png' -exec optipng -o5 {} \;
find -E _site -type f -regex '.*\.(html|css|js|svg|xml)' -exec gzip -n "{}" \; -exec mv "{}.gz" "{}" \;

# Sync gziped files
s3cmd --acl-public \
      --cf-invalidate -M \
      --rinclude '.*\.(html|css|js|svg|xml)' \
      --add-header="Cache-Control: max-age=604800" \
      --add-header 'Content-Encoding:gzip' \
      sync _site/ s3://sylvain.durand.tf/ 

# Sync other files
s3cmd --acl-public \
      --cf-invalidate -M \
      --rexclude '.*\.(html|css|js|svg|xml)' \
      --add-header="Cache-Control: max-age=6048000" \
      sync _site/ s3://sylvain.durand.tf/ 

# Delete removed files
s3cmd --delete-removed \
      --cf-invalidate-default-index \
      sync _site/ s3://sylvain.durand.tf/ 
