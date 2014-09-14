---
title: Utiliser Github <br/> pour servir <em>Jekyll</em>
---

G*itHub* a créé un fantastique écosystème autour du générateur de sites statiques *Jekyll*. 


Dans cet article, nous verrons comment :

* stocker votre site dans un répertoire sur [*GitHub*](https://github.com/) ;
* générer le site à la volée et le servir avec [*GitHub Pages*](https://pages.github.com/) ;
* rédiger directement ses articles en ligne grâce à [*Prose*](http://prose.io/) ;
* tester en permanence la compilation et les liens avec [*Travis*](https://travis-ci.org/).


## Stocker son site sur *GitHub*

### Création du compte 
Si vous n'en avez pas déjà un, créez un compte directement depuis la [page d'accueil de GitHub](https://github.com/) en renseignant un nom d'utilisateur[[attention, le choix du nom d'utilisateur est important, puisqu'il détermine l'URL par défaut à laquelle votre site sera accessible, et le nom du répertoire]], une adresse email et un mot de passe.

### Création du répertoire sur *GitHub*
Sur votre page de profil, cliquez sur "Repositories" puis "New" afin de créer un nouveau répertoire qui contiendra notre site. Le nom de ce répertoire doit obligatoirement être "`username.github.io`", où `username` est le nom d'utilisateur choisi à l'inscription. C'est également à cette même adresse que notre site sera disponible.

Choisissez l'option "*Initialize this repository with a README*", pour créer une description au répertoire que nous pourrons modifier plus tard, mais surtout pour pouvoir utiliser directement `git clone`.

Si vous possédez un compte GitHub payant, il vous est par ailleurs possible de créer un répertoire privé, afin de ne pas rendre les codes publics ; néanmoins, dans le cas d'un simple site en *Jekyll*, cette option n'est sans doute pas très importante.

### Synchronisation du répertoire en local
Désormais, sur votre ordinateur local, créez le dossier qui accueillera votre site, ouvrez un terminal dans ce dossier, et clonez le répertoire fraîchement créé :

```bash
git clone https://github.com/username/username.github.io.git
cd username.github.io
```

Commençons par créer un fichier **`.gitignore`** qui va nous permettre de ne pas prendre en compte le répertoire `_site` dans lequel le site est généré[[il n'est en effet pas important de suivre ces fichiers, qui ne dépend qu'un résultat du code à proprement parler]], le fichier `Gemfile.lock` qui sera créé automatiquement tout à l'heure, et si vous êtes sur Mac OS X les dossiers `.DS_Store` que le système d'exploitation crée un peu partout. Ce fichier `.gitignore contient donc :

```bash
_site
Gemfile.lock
.DS_Store
```

Nous pouvons alors envoyer ce fichier .gitignore :

```bash
git add .gitignore
git commit -m "First commit"
git push
```

Indiquez à ce moment votre nom d'utilisateur et votre mot de passe pour pouvoir "pousser" votre première modification.

### Synchronisation du site
Il ne vous reste désormais qu'à placer les fichiers de votre site *Jekyll* dans ce répertoire. Il peut soit s'agir d'un site que vous avez précédemment créé, soit d'un nouveau site créé avec `jekyll new`[[l'article [Site statique avec *Jekyll*](http://sylvain.durand.tf/site-statique-avec-jekyll/) explique comment créer un site simple sous *Jekyll*]].

Il est alors facile d'apporter une modification au site avec `git` :

* **git add** pour ajouter les modifications pour le prochain envoi ;
* **git commit** pour valider ce prochain envoi ;
* **git push** pour envoyer ces modifications à *GitHub*.

Par exemple, pour envoyer notre nouveau site, on ajoute l'ensemble des nouveaux fichiers, on réalise le "commit" et on le "pousse" à *GitHub* :

```bash
git add --all
git commit -m "Description des modifications apportées"
git push
```

Maintenant que l'ensemble du code source 

## Servir son site sur *GitHub Pages*



### Avoir le même environnement en local



### Activer GitHub Pages

### Utiliser un nom de domaine personnalisé

### Pages d'erreur 404




## Pour aller plus loin

### Rédiger et modifier ses articles en ligne avec *Prose* 

### Utiliser *Travis* pour vérifier la compilation du site





