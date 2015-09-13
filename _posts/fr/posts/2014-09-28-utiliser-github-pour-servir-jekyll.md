---
title: Utiliser Github <br/> pour servir <em>Jekyll</em>
---

G*itHub* a créé un fantastique écosystème autour du générateur de sites statiques *Jekyll*. *[GitHub Pages](https://pages.github.com/)* permet en effet de générer puis de servir automatiquement les sites *Jekyll*. Ce service, gratuit et très performant, permet de réunir les meilleurs aspects des sites statiques – rapidité, fiabilité, sécurité, possibilité d'utiliser `git` – tout en permettant leur édition en ligne.

Nous avons vu dans des articles précédents comment [créer un site statique avec *Jekyll*]({{site.base}}/site-statique-avec-jekyll/), puis comment [le servir avec *Cloudfront*]({{site.base}}/servir-son-site-avec-cloudfront/). À la place, nous allons montrer dans cet article comment :

* synchroniser votre site avec `git` sur [*GitHub*](https://github.com/) ;
* générer le site à la volée et le servir avec [*GitHub Pages*](https://pages.github.com/) ;
* rédiger directement ses articles en ligne grâce à [*Prose*](http://prose.io/) ;
* tester la compilation, le HTML et les liens avec [*Travis*](https://travis-ci.org/).


## Stocker son site sur *GitHub*

### Création du compte
Si vous n'en avez pas déjà un, créez un compte sur [*GitHub*](https://github.com/) en renseignant un nom d'utilisateur[[attention, le choix du nom d'utilisateur est important, puisqu'il détermine l'URL par défaut à laquelle votre site sera accessible, et le nom du répertoire]], une adresse email et un mot de passe ; dans le cas contraire, connectez-vous avec vos identifiants.

### Création du répertoire sur *GitHub*
Sur votre page de profil, cliquez sur *Repositories* puis *New* afin de créer un nouveau répertoire qui contiendra notre site. Le nom de ce répertoire doit obligatoirement être `username.github.io`, où `username` est le nom d'utilisateur choisi à l'inscription. C'est également à cette même adresse que notre site sera disponible.

Choisissez l'option *Initialize this repository with a README* pour pouvoir utiliser directement `git clone`.

Si vous possédez un compte *GitHub* payant, il vous est par ailleurs possible de créer un répertoire privé, afin de ne pas rendre les codes publics[[néanmoins, dans le cas d'un simple site *Jekyll*, cette option n'est sans doute pas très importante]].

### Synchronisation du répertoire en local
Sur votre ordinateur local, créez le dossier qui accueillera votre site, ouvrez un terminal dans ce dossier, et clonez le répertoire fraîchement créé :

```bash
git clone https://github.com/username/username.github.io.git
cd username.github.io
```

Commençons par créer un fichier `.gitignore` qui va nous permettre de ne pas prendre en compte le répertoire `_site` dans lequel le site est généré[[il ne faut en effet pas suivre ce dossier, qui ne dépend qu'un résultat du code à proprement parler]], le fichier `Gemfile.lock` qui sera créé tout à l'heure, et si vous êtes sur OS X les dossiers `.DS_Store` créés par le système d'exploitation. Le fichier `.gitignore` ressemblera donc à :

```bash
_site
Gemfile.lock
.DS_Store
```

Nous pouvons alors envoyer ce fichier sur *GitHub*[[lors du premier `push`, vous devrez indiquer votre nom d'utilisateur et votre mot de passe, mais ceux-ci ne seront plus demandés ensuite]] :

```bash
git add .gitignore
git commit -m "First commit"
git push
```

### Synchronisation du site
Il ne vous reste désormais qu'à placer les fichiers de votre site *Jekyll* dans ce répertoire. Il peut soit s'agir d'un site que vous avez précédemment créé, soit d'un nouveau site créé avec `jekyll new`[[l'article [Site statique avec *Jekyll*]({{site.base}}/site-statique-avec-jekyll/) explique comment créer un site simple sous *Jekyll*]].

Il est alors facile d'apporter une modification au site avec `git` :

* `git add` ajoute les modifications pour le prochain envoi ;
* `git commit` valide ce prochain envoi ;
* `git push` envoie ces modifications à *GitHub*.

Par exemple, pour envoyer notre nouveau site, on ajoute l'ensemble des nouveaux fichiers, on utilise `git commit` puis `git push` à *GitHub* :

```bash
git add --all
git commit -m "Première version du site"
git push
```

Notre site n'étant composé que de simples fichiers texte, vous pouvez utiliser *git* comme avec n'importe quels projets. De nombreuses références existent si `git` ne vous est pas familier[[vous pouvez par exemple consulter [Git, le petit guide](http://rogerdudler.github.io/git-guide/index.fr.html) pour une introduction rapide, ou le livre [Pro Git](http://git-scm.com/book/fr) pour une introduction plus complète]].

## Servir son site sur *GitHub Pages*

Nous allons désormais voir comment faire en sorte que *GitHub* génère le site, puis l'héberge sur ses serveurs. Il suffira par la suite d'utiliser `git push` pour que *GitHub* compile et serve la dernière version de votre site.


### Avoir le même environnement en local
À chaque fois que vous utiliserez `git push`, votre site sera automatiquement mis à jour.

C'est pourquoi, pour éviter de casser notre site en ligne, il est important de s'assurer que tout fonctionne correctement en local, et donc avoir exactement le même environnement, c'est-à-dire la même version de *Jekyll* et les mêmes dépendances que celles utilisées par *GitHub*. La meilleure façon pour ce faire est d'utiliser `bundler`[[si vous ne le possédez pas, installer-le avec `gem install bundler`]].

Commencez par créer, à la racine, un fichier `Gemfile` qui fait référence à la gemme `github-pages`, qui indique automatiquement les versions et dépendances utilisées par *GitHub* :

```bash
source 'https://rubygems.org'
gem 'github-pages'
```

Utilisez alors `bundle install` pour installer automatiquement toutes les dépendances. La commande `bundle update` vous permettra régulièrement ensuite de mettre vos dépendances à jour.

La commande `bundle exec jekyll serve` générera alors votre site exactement comme le fera *Github*. Vous pouvez alors l'observer à l'adresse `http://localhost:4000`.

### Activer *GitHub Pages*
De retour sur *GitHub*, allez dans votre répertoire `username.github.io` puis dans `Settings`, et dans la rubrique `GitHub Pages` pour activer la génération de votre site.

Au bout de quelques instants (la première fois, cela pourra prendre une dizaine de minutes, mais ensuite le site sera mis à jour en quelques secondes), votre site sera disponible à l'adresse `http://username.github.io`[[le site est également disponible en HTTPS à l'adresse `https://username.github.io`]].

### Utiliser un nom de domaine personnalisé
Si vous possédez votre nom de domaine personnalisé "`domain.tld`", il est bien sûr possible de l'utiliser à la place de l'adresse proposée par *GitHub*. Celle-ci redirigera alors vers votre nouveau nom de domaine. Il ne vous sera cependant pas possible d'utiliser HTTPS[[si vous essayez d'accéder à l'adresse ``https://domain.tld`, il apparaît une page blanche indiquant `unknown domain: domain.tld`]].

Si vous souhaitez utiliser uniquement un sous-domaine `subdomain.domain.tld`, créez chez votre fournisseur de nom de domaine un enregistrement `CNAME` avec pour nom `subdomain` et pour valeur `username.github.io`. Créez alors un fichier nommé `CNAME` contenant exactement `subdomain.domain.tld` à la racine.

Si vous voulez utiliser la racine de votre nom de domaine, suivez la [documentation de *GitHub*](https://help.github.com/articles/about-custom-domains-for-github-pages-sites).

### Page d'erreur 404
*GitHub* permet d'obtenir une page d'erreur 404 personnalisée[[lorsque vous testez votre site en local avec `bundle exec jekyll serve`, cette page d'erreur est également fonctionnelle : vous pouvez la tester en entrant une URL incorrecte]] : il suffit pour cela de demander à *Jekyll* de générer une page `404.html` à la racine :

```html
---
title: Page introuvable
permalink: /404.html
---

La page recherchée a probablement été supprimée ou déplacée.
```

## Pour aller plus loin

### Rédiger et modifier ses articles en ligne avec *Prose*
L'un des principaux désavantages des sites statiques vis-à-vis des CMS est de ne pas pouvoir être facilement modifiables en ligne.

Notre site étant hébergé sur *GitHub*, il est possible d'y modifier directement les fichiers, *Pages* se chargeant de regénérer le site à chaque modification. Il est également possible d'utiliser le site *[Prose.io](http://prose.io/)*, qui offre une belle interface avec coloration syntaxique et prévisualisation pour rédiger ses articles.

Directement depuis le site *[Prose.io](http://prose.io/)*, connectez-vous avec vos identifiants *GitHub* et autorisez *Prose* à accéder à vos répertoires. Il vous est alors possible de créer et de modifier directement des articles, ou tous les autres fichiers du site.

Une fois les modifications acceptées, il vous est possible d'effectuer un `commit`, suite à quoi *GitHub* va générer le site.


### Utiliser *Travis* pour vérifier la compilation du site

Le service *[Travis](https://travis-ci.org/)* permet de compiler lui-même votre site à chaque *push*, afin de vous assurer qu'il n'y a pas d'erreur. Il est également possible d'ajouter d'autres tests, notamment `htmlproofer` pour vérifier la conformité de votre code HTML et s'il existe des liens morts. En cas de problème, vous serez prévenus par email.

Pour cela, entrez vos identifiants *GitHub* sur *[Travis](https://travis-ci.org/)* puis activez la surveillance de votre répertoire `username.github.io`. Ajoutez ensuite `htmlproofer` dans votre fichier `Gemfile`, qui devient alors :

```
source 'https://rubygems.org'
gem 'github-pages'
gem 'html-proofer'
```

Créez alors un fichier `.travis.yml` contenant les instructions permettant de générer le site, puis de le tester :

```
language: ruby
rvm:
- 2.1.1
script:
- bundle exec jekyll build && bundle exec htmlproof ./_site
```

Désormais, à chaque *push*, *Travis* vous avertira par email si *Jekyll* ne parvient pas à compiler votre site, si le code HTML produit n'est pas valide ou s'il existe un lien mort.


