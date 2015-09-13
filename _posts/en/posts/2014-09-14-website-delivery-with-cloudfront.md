---
title: Website delivery <br/> with <em>Cloudfront</em>
redirect_from: /static-website-with-cloudfront/
---

The main interest of static website is to be able to be stored in the *cloud*, that is to say on a content delivery network able to serve our data with amazing performances, a very low cost, and multiple benefits in terms of lightness, safety and reliability.

This article sets out to show how to host a static website[[wether built from a generator like [*Jekyll*](http://jekyllrb.com), [*Pelican*](http://docs.getpelican.com/) or [*Hyde*](http://hyde.github.io), or "by hand"]] on [*Amazon Web Services*](http://aws.amazon.com), especially [*Amazon S3*](http://aws.amazon.com/s3/) in order to store the website files, and [*CloudFront*](http://aws.amazon.com/cloudfront/) in order to deliver them. The main purpose is to be able to get a website fast from anywhere, reliable, secure, highly scalable and inexpensive[[with a low traffic, the hosting will cost you about one dollar a month]].

To this purpose, we will use:

* [*S3*](http://aws.amazon.com/s3/) in order to store the website;
* [*CloudFront*](http://aws.amazon.com/cloudfront/) in order to deliver our data;
* [*Route 53*](http://aws.amazon.com/route53/) in order to use our domain name.
* [*Awstats*](http://awstats.sourceforge.net/) in order to analyse the logs.



## Hosting on *S3*
After having created an [*AWS*](http://aws.amazon.com/) account, go to the [management console](https://console.aws.amazon.com/), then to [*S3*](https://console.aws.amazon.com/s3/): this service will store the website files.

### Creating buckets
The website will be located on `www.domain.tld`. The domain name root, `domain.tld`, will redirect to this location. Create two buckets (with `Create bucket`) named from the expected URL: `domain.tld` and `www.domain.tld`.

### Bucket hosting the website
In `www.domain.tld` properties, activate website hosting (`Static Website Hosting` then `Enable website hosting`): you can choose a home page (`index.html`) or an error page (`error.html`). The website will be available from the  `Endpoint` URL: *keep it*, we will need it in the following section.

### Buckets redirecting
In `domain.tld` properties, choose `Static Website Hosting` in order to select `Redirect all requests`: we provide `domain.tld`. This bucket will stay empty.

From `Endpoint` location, we can now see the files hosted in `www.domain.tld` bucket. We can upload those files from the *AWS* console, but we will explain on the last part how to upload it with one bash command line.



## Serving data with *Cloudfront*

*S3* hosts our data in one unique location. Data stored in Dublin will be provided quite fast to a visitor located in Paris (about 200 ms in order to load the home page of this website) but less in New-York (500 ms) or Shanghai (1,300 ms).

*Amazon CloudFront* is a [CDN](http://fr.wikipedia.org/wiki/Content_delivery_network), serving content to end-users with high availability and high performance. The access time falls below 100 ms in Paris, New-York and Shanghai.

In return, a propagation delay exists between an upload and its update on *Cloudfront*. We will see in the last part how to notify any modification.



### Creating the distribution

In the *AWS* management console, choose *CloudFront*, `Create Distribution`, then `Web`.

In `Origin Domain Name`, we provide the address previously copied, similar to `www.domain.tld.s3-website-eu-west-1.amazonaws.com`. The field will automatically propose an other value (like `www.domain.tld.s3.amazonaws.com`); *don't* click on it: URL ending with `/` wouldn't lead to `/index.html`. Choose an ID in `Origin ID`.

Leave the other field as default, except `Alternate Domain Names` where we provide our domain name: `www.domain.tld`. Indicate the homepage in `Default Root Object`: `index.html`.

Our distribution is now created: we can now activate it with `Enable`. `InProgress`  status means *Cloudfront* is currently propagating our data; when it's over, the status will become `Deployed`.


## Domain name with *Route 53*

### Creating zone
*Route 53* service will allow us to use our own domain name. In *AWS* console management, select *Route 53* then `Create Hosted Zone`. In `Domain Name`, put your domain name without any sub-domain: `domain.tld`.

### Redirecting DNS
Select the newly created zone, then the `NS` type. Its `Value` field gives 4 addresses. Tell your registrar to make the DNS pointing to them.

### Domain with *Cloudfront*
Back to *Route 53*, in `domain.tld`, create 3 records set with `Create Record Set`:

* `domain.tld` (put  `www` in `name`), `A` type: in `Alias`, select our *Cloudfront* distribution;
* `domain.tld`, `A` type: select the same name bucket.

Of course, it is possible to redirect sub-domains to other services (with NS, A and CNAME records) and to use mails (MX records).


Now, an user going to `domain.tld` or `www.domain.tld` will target the same name buckets (thanks to *Route 53*) which redirect to `www.domain.tld` (thanks to *S3*). This address directly leads (thanks to *Route 53*) to the *Cloudfront* distribution, which provides our files stored in the  bucket `www.domain.tld`. Now, we just have to send our website to *Amazon S3*.






## Deploying *Jekyll* to the cloud

We will now create a `sh` file which will build the website, compress and send to *Amazon S3* files which has been updated since the previous version, and indicate it to *Cloudfront*.

### Prerequisite

We will use `s3cmd` in order to sync our bucket with our local files. Install the last development version[[you need to install at least the 1.5 version]] which allows us to invalidate files on *Cloudfront*.

On Mac OS, with *Homebrew*, install `s3cmd` with `--devel` option, and `gnupg` for secured transfers:

```bat
brew install --devel s3cmd
brew install gpg
```

Now we have to gives `s3cmd` the ability to deal with our *AWS* account. In [Security Credentials](https://console.aws.amazon.com/iam/home?#security_credential), go to `Access Key` and generate one access key and its secret Key. Then configure `s3cmd` with  `s3cmd --configure`.

In order to optimize images, we will install `jpegoptim` and `optipng`:

```bat
sudo brew install jpegoptim
sudo brew install optipng
```



### Building Jekyll and compressing files

We first build *Jekyll* into the `_site` folder:

```bat
jekyll build
```

Using `jekyll-press` plugin will optimize HTML, CSS and JS files. If `jpegoptim` and `optipng` are installed, we can optimize images:

```bat
find _site -name '*.jpg' -exec jpegoptim --strip-all -m80 {} \;
find _site -name '*.png' -exec optipng -o5 {} \;
```


Then, in order to improve performances, we compress HTML, CSS and JS files with Gzip, that is to say all files out of `static/` folder:

```bat
find _site -path _site/static -prune -o -type f \
-exec gzip -n "{}" \; -exec mv "{}.gz" "{}" \;
```



### Uploading files to *Amazon S3*

We use `s3cmd` to upload the website; only the updated files will be sent. We use the following options:

* `acl-public` make our files public;
* `cf-invalidate` warn *Cloudfront* files have to be updated;
* `add-header` defines headers (compression, cache duration...);
* `delete-sync` delete files removed locally;
* `M` defines files MIME type.

We first send static files, stored in `static/`, assigning them a 10 weeks cache duration:

```bat
s3cmd --acl-public --cf-invalidate -M \
      --add-header="Cache-Control: max-age=6048000" \
      --cf-invalidate \
      sync _site/static s3://www.domain.tld/
```

Then we send the other files (HTML, CSS, JS...) with a 48 hours cache duration:

```bat
s3cmd --acl-public --cf-invalidate -M \
      --add-header 'Content-Encoding:gzip' \
      --add-header="Cache-Control: max-age=604800" \
      --cf-invalidate \
      --exclude="/static/*" \
      sync _site/ s3://www.domain.tld/
```

Finally we clean the bucket by deleting files which have been deleted in the local folder, and we invalidate the home page on *Cloudfront* (`cf-invalidate` doesn't do it):

```bat
s3cmd --delete-removed --cf-invalidate-default-index \
      sync _site/ s3://www.domain.tld/
```




### Deploy in one single command

We put those command in one single file, named `_deploy.sh`, located in *Jekyll* folder:

```sh
#!/bin/sh
# Building Jekyll
jekyll build

# Compressing and optimizing files
find _site -path _site/static -prune -o -type f \
      -exec gzip -n "{}" \; -exec mv "{}.gz" "{}" \;
find _site -name '*.jpg' -exec jpegoptim --strip-all -m80 {} \;
find _site -name '*.png' -exec optipng -o5 {} \;

# Synchronisation des médias
s3cmd --acl-public --cf-invalidate -M \
      --add-header="Cache-Control: max-age=6048000" \
      --cf-invalidate \
      sync _site/static s3://www.domain.tld/

# Sync media
s3cmd --acl-public --cf-invalidate -M \
      --add-header 'Content-Encoding:gzip' \
      --add-header="Cache-Control: max-age=604800" \
      --cf-invalidate \
      --exclude="/static/*" \
      sync _site/ s3://www.domain.tld/

# Delete removed files
s3cmd --delete-removed --cf-invalidate-default-index \
      sync _site/ s3://www.domain.tld/
```

You only have to execute `sh _deploy.sh` to update the website. A few minutes may be required in order to update *CloudFront* data.


## Stats

Although our site is static and served by a CDN, it is quite possible to analyze the logs if you do not want to use a system based on a javascript code, such as [Piwik](http://piwik.org/) or [Google Analytics](https://www.google.fr/intl/en/analytics/). Here, we will automate the task (recovery logs, processing and displaying statistics) from a server (in our example, a Raspberry Pi in Raspbian) and we will use [*Awstats*](http://awstats.sourceforge.net/).

### Retrieving logs

Let's start by activating logs creation on our *Cloudfront* distribution. In the AWS Management Console, select the *Amazon S3* service and create a "statistics" bucket which will store logs waiting to be retrieved. Then, in *Cloudfront*, select the distribution that provides our website, then `Distribution` settings, `Edit`, and select the `statistics` bucket in the field `Bucket for Logs`.

We create locally a folder that will retrieve these logs, then we can then retrieve the logs and then delete the bucket using `s3cmd`:

```bat
mkdir ~/awstats
mkdir ~/awstats/logs
s3cmd get --recursive s3://statistics/ ~/awstats/logs/
s3cmd del --recursive --force s3://statistics/
```

### Installing and configuring *Awstats*

We begin by installing and copy *Awstats* (where `www.domain.tld` is your domain name):

```bat
sudo apt-get install awstats
sudo cp /etc/awstats/awstats.conf \
        /etc/awstats/awstats.www.domain.tld.conf
sudo nano /etc/awstats/awstats.www.domain.tld.conf
```

In this configuration file, change the following settings to specify how to treat *Awstats* logs *Cloudfront* (where `user` is your username):

```bat
# Processing multiple gzip logs files
LogFile="/usr/share/awstats/tools/logresolvemerge.pl /home/user/awstats/logs/* |"
# Formating Cloudfront generated logs
LogFormat="%time2 %cluster %bytesd %host %method %virtualname %url %code %referer %ua %query"
LogSeparator="\t"
# Domain names (website and Cloudfront)
SiteDomain="www.domain.tld"
HostAliases="REGEX[.cloudfront\.net]"
```

Finally, we copy the images which will be displayed in the reports:

```bat
sudo cp -r /usr/share/awstats/icon/ ~/awstats/awstats-icon/
```

### Generating stats

Once this configuration is done, it is possible to generate statistics as a static HTML file using:

```bat
/usr/share/awstats/tools/awstats_buildstaticpages.pl \
    -dir=~/awstats/ -update -config=www.domain.tld \
```

The statistics are now readable from the `awstats.www.domain.tld.html` file. It is then possible to publish it, send it to a server or email for example.


### Regular updating

To automate the generation of statistics at regular intervals, creating a `stats.sh` with `nano ~ / awstats / stats.sh` that retrieves logs and generates statistics:

```sh
#!/bin/sh
# Retrieving logs
s3cmd get --recursive s3://statistics/ ~/awstats/logs/
s3cmd del --recursive --force s3://statistics/
# Generating stats
/usr/share/awstats/tools/awstats_buildstaticpages.pl \
    -dir=~/awstats/ -update -config=www.domain.tld \
```

We give the rights to this file so it can be executed, and then create a cron task:

```bat
sudo chmod 711 ~/awstats/stats.sh
sudo crontab -e
```

To generate statistics of every six hours for example:

```r
0 */6 * * * ~/awstats/stats.sh
```
