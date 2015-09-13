---
title: Using Github <br/> to serve <em>Jekyll</em>
---

G*itHub* has created a wonderful ecosystem built around the static websites generator *Jekyll*. *[GitHub Pages](https://pages.github.com/)* allows to generate, then to serve automatically *Jekyll* websites. This service, free and quite effective, brings together the best aspects of static websites – speed, reliability, security, ability to use `git` – while allowing their modification online.

In the previous articles, we saw how to [create a static website with *Jekyll*]({{site.base}}/static-website-with-jekyll/), then how to [deliver it with *Cloudfront*]({{site.base}}/website-delivery-with-cloudfront/). This article aims to show how to:

* synchronize your website with `git` on [*GitHub*](https://github.com/) ;
* generate and serve it on the fly with [*GitHub Pages*](https://pages.github.com/) ;
* write articles directly on line thanks to [*Prose*](http://prose.io/) ;
* test compilations, HTML validity and links with [*Travis*](https://travis-ci.org/).


## Hosting our website on *GitHub*

### Account creation
If you haven't already got one, create an account on [*GitHub*](https://github.com/) by providing an username[[beware, the username is important, because it will be used in the repository and the URL used by *GitHub Pages*]], an email address and a password; otherwise, use your usual login informations.

### Creating the repository
In your profile page, choose *Repositories* then *New* in order to create the repository which will host our website. The repository name has to be `username.github.io`, where `username` is the one you provided when you signed up. The website will also be available on this location.

Choose the *Initialize this repository with a README* option in order to be able to use directly `git clone`.

If you have got a *GitHub* paid plans, you can create a private repositoty in order to hide your codes[[in the case of a simple *Jekyll* website, this option may not be really useful]].

### Synchronizing our local folder
On your computer, create the folder where the website will be stored, then open a terminal and clone the newly created repository:

```bash
git clone https://github.com/username/username.github.io.git
cd username.github.io
```

Let's start by creating a `.gitignore` file which will allow us to ignore the `_site` repository in which the website will be generated[[we musn't check this folder, which is only a result of the source code]], the `Gemfile.lock` file we will create later, and if you use on OS X the `.DS_Store` folders created by the operating system. The `.gitignore` file will looks like:

```bash
_site
Gemfile.lock
.DS_Store
```

We can now push this file on *GitHub*[[when you `push` for the first time, you have to provide your username and your password, but they won't be asked again]] :

```bash
git add .gitignore
git commit -m "First commit"
git push
```

### Synchronizing the website
Now, you only have to put your *Jekyll* website in this folder. It may be an existing website, or a newly created one thanks to `jekyll new`[[the article [Creating a static website with *Jekyll*]({{site.base}}/static-website-with-jekyll/) explains how to create a simple website with *Jekyll*]].

It is then easy to maintain and edit the website with `git` :

* `git add` add the changes for the next commit;
* `git commit` valids thoses changes;
* `git push` sends them on *GitHub*.

For instance, in order to send our new website, we add every file, then we use  `git commit` then `git push` :

```bash
git add --all
git commit -m "First version"
git push
```

Because the website only use simple text files, you can use *git* as you would do with any other project. Many references exists if you are not familiar with `git`[[for example, you can read [Git, a simple guide](http://rogerdudler.github.io/git-guide/) for a short introduction, or the more complete [Pro Git](http://git-scm.com/book) book]].

## Serving *Jekyll* on *GitHub Pages*

We will now see how to use *GitHub* to generate, then host and serve the website. You will just have to use `git push` in order to make *GitHub* generating and serving the last version of your website.


### Being able to reproduce *GitHub* settings
Each time you will use `git push`, your website will be automatically generated on *GitHub*.

This is why it is highly important to make sure everything is going to work perfectly, if we don't want to break our website online. In order to ensure your computer most closely matches the GitHub Pages settings, the best way to do is to use `bundler`:

```
gem install bundler
```

Then, create on the root a `Gemfile` file which will tells to use the `github-pages` gem, which provide automatically the last versions and dependancies used by *GitHub*:

```bash
source 'https://rubygems.org'
gem 'github-pages'
```

You can then use `bundle install` in order to install the gem(s). The `bundle update` command will ensure you always have an up to date system.

The `bundle exec jekyll serve` command will now generate the website exactly as *Github* would do, so you can check on `http://localhost:4000` that everything is right before pushing anything.

### Activating *GitHub Pages*
Back on *GitHub*, go in the `username.github.io` repository, choose `Settings`, then the `GitHub Pages` section in order to activate the website generation.

Within a few moments (the first time, it can take a dozen of minutes, but then the website will be generated in a couple of seconds each time you push a commit), your website will be available on `http://username.github.io`[[it is also available in HTTPS on `https://username.github.io`]].

### Using a custom domain name
If you have a custom domain name "`domain.tld`", it is of course possible to use it instead of the default URL given by *GitHub*, which will then redirect to the new domain name. However, it won't be possible to use HTTPS[[if you try to go to ``https://domain.tld`, you will get a blank page showing `unknown domain: domain.tld`]].

If you want to use a subdomain `subdomain.domain.tld`, tell your registar to create a `CNAME` record, with the `subdomain` name and the `username.github.io` value. Then, create a file named `CNAME` on the root of the repository, containing exactly `subdomain.domain.tld`.

If you want to use an Apex domain, follow the [GitHub guide](https://help.github.com/articles/about-custom-domains-for-github-pages-sites).

### Custom 404 error page
*GitHub* allows you to have a custom 404 error page. When you test your website locally with `bundle exec jekyll serve`, this error page also works: you can try by providing an incorrect URL. Just tell *Jekyll* to create a `404.html` on the root:

```html
---
title: Page not found
permalink: /404.html
---

This page must have been removed or had its name changed.
```

## To go further

### Writing and editing your articles online with *Prose*
One of the main disadvantages of static websites is the impossibility to edit them online without your computer.

Because your website is hosted on *GitHub*, it is possible to modify files directly online. Jekyll generates *Pages* each time you modify a page. You can also use the *[Prose.io](http://prose.io/)* website, which provides a nice interface, a great syntax highlighting and a preview system in order to write your articles.

On the *[Prose.io](http://prose.io/)* website, use your *GitHub* login information and allow *Prose* to see and change your repositories. You can then create and edit your articles, or any other file of the website.

### Using *Travis* to check your website

*[Travis](https://travis-ci.org/)* allows your to generate the website each time you *push* something, in order to check nothing is wrong. It is also possible to add some other tests like `htmlproofer` which checks if the HTML code is valid and there are no rotten links. You will get a warning email if something is wrong.

To do so, use your *GitHub* login informations on *[Travis](https://travis-ci.org/)*, then enable the `username.github.io` repository. Then, add `htmlproofer` in your `Gemfile` file, which now looks like:

```
source 'https://rubygems.org'
gem 'github-pages'
gem 'html-proofer'
```

Finally, create a `.travis.yml` file in order to tell *Travis* how to build and test the website:

```
language: ruby
rvm:
- 2.1.1
script:
- bundle exec jekyll build && bundle exec htmlproof ./_site
```

Now, each time you push something, *Travis* will send you an email if *Jekyll* can't generate your website, if the HTML code is not valid or if a link rot remains.


