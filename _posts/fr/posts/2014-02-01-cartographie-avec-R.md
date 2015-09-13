---
title: Cartographie <br/> avec <em>R</em>
---

Si le langage _R_ est devenu une référence en analyse statistiques et en traitement de données, c'est sans doute en partie grâce à ses fonctionnalités graphiques. Celles-ci peuvent également être utilisées pour représenter des données sous forme de cartes, ce qui, combiné avec ses autres fonctionnalités, en fait un système d'information géographique à part entière. L'objectif de cet article est de montrer, à travers quelques exemples, comment représenter simplement des données sur des cartes.

### Prérequis
En plus de l'installation de _R_ sur votre machine, quelques librairies vont être nécessaires : `rgdal` permet d'importer les cartes et de les projeter, `plotrix` permet de créer des échelles de couleurs et `classInt` les affecte selon les données. Une fois les librairies installées à l'aide de `install.packages`, on les charge en début de session :

```r
library('rgdal')      # Lire et reprojeter les cartes
library('plotrix')    # Créer des échelles de couleurs
library('classInt')   # Affecter ces couleurs aux données
```


Les graphiques seront générés à l'aide des fonctions graphiques de base de *R*. `ggplot2` est également populaire, mais celui-ci semble moins pertinent pour des cartes : code plus long et moins lisible, incapacité à tracer des trous dans des polygones et `fortify` comme le traçage peuvent prendre un temps très long : pour tracer les 36 000 communes françaises, `fortify` et `ggplot` prennent chacun plusieurs dizaines de minutes, contre à peine 20 secondes pour `plot`.



## Cartes française vierge

### Lecture des frontières

La librairie `rgdal` fournit `readOGR()` qui permet de lire les fichiers shapefiles. L'argument `dsn` doit contenir le chemin vers le dossier contenant les fichiers shapefiles et l'argument `layer` le nom du fichier, sans extension. `readOGR` lira les fichiers `.shp`, `.shx`, `.dbf` et s'il existe le fichier `.prj` qui contient les informations sur la projection utilisée.

Les données utilisées pour les départements sont fournies par l'IGN avec [Geofla](http://professionnels.ign.fr/geofla) :

```r
# Lecture des départements
departements <- readOGR(dsn="shp/geofla",  layer="DEPARTEMENT")

# Lecture des limites départementales pour sélectionner les frontières
frontieres <- readOGR(dsn="shp/geofla",  layer="LIMITE_DEPARTEMENT")
frontieres <- frontieres[frontieres$NATURE %in% c('Fronti\xe8re internationale','Limite c\xf4ti\xe8re'),]
```


Pour afficher les pays environnants en fond de carte, nous utilisons les données fournies par [Natural Earth](http://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/). On limite celles-ci à l'Europe :

```r
# Lecture des pays et sélection de l'Europe
europe <- readOGR(dsn="shp/ne/cultural", layer="ne_10m_admin_0_countries")
 <- europe[europe$REGION_UN=="Europe",]
```


### Projection et traçage

Notre carte utilisera la projection Lambert 93, [projection officielle](http://www.legifrance.gouv.fr/affichTexte.do?cidTexte=JORFTEXT000000387816&fastPos=1&fastReqId=2039166907&categorieLien=cid&oldAction=rechTexte) pour la France métropolitaine. Celle-ci est déjà définie par défaut dans les fichiers `.prj` de Geofla. Pour l'Europe, on utilise `spTransform`.

La carte peut alors être générée à l'aide de `plot` : on affiche en premier les frontières françaises, afin que le graphique soit centré sur la France. La couleur des bordures de chaque objet sont définies avec `border`, leur épaisseur avec `lwd` et le remplissage avec `col`.


```r

# Projection en Lambert 93
europe <- spTransform(europe, CRS("+init=epsg:2154"))

# Traçage de la carte
pdf('france.pdf',width=6,height=4.7)
par(mar=c(0,0,0,0))

plot(frontieres,  col="#FFFFFF")
plot(europe,      col="#E6E6E6", border="#AAAAAA",lwd=1, add=TRUE)
plot(frontieres,  col="#D8D6D4", lwd=6, add=TRUE)
plot(departements,col="#FFFFFF", border="#CCCCCC",lwd=.7, add=TRUE)
plot(frontieres,  col="#666666", lwd=1, add=TRUE)

dev.off()
```

[![Carte de France]({{site.base}}/medias/carto/france.jpg)]({{site.base}}/medias/carto/france.pdf)

## Coloration d'une donnée : densité de population


### Lecture des données
Le très grand nombre de communes en France offre un très beau maillage pour les représentations graphiques. Les données sont fournies par Geofla, qui fournit la population et la superficie de chaque commune. Nous allons essayer de représenter la densité de population.

```r
# Lecture des communes
communes     <- readOGR(dsn="shp/geofla", layer="COMMUNE")

# Calcul de la densité.
communes$DENSITE <- communes$POPULATION/communes$SUPERFICIE*100000
```


### Création de l'échelle de couleurs
Il nous faut maintenant choisir une échelle de couleurs : nous allons ici affecter une nuance de bleu à chaque centile. `classIntervals` calcule les déciles, `smoothColors` crée nos dégradés de bleus, et `findColours` affecte ces bleus aux communes en fonction de leur densité. Créons par ailleurs une légende ne contenant que cinq couleurs. On utilise pour cela les mêmes fonctions.


```r
# Échelle de couleurs
col <- findColours(classIntervals(
            communes$DENSITE, 100, style="quantile"),
            smoothColors("#0C3269",98,"white"))
# Légende
leg <- findColours(classIntervals(
            round(communes$DENSITE), 5, style="quantile"),
            smoothColors("#0C3269",3,"white"),
            under="moins de", over="plus de", between="–",
            cutlabels=FALSE)
```

### Traçage de la carte
Nous pouvons alors tracer notre carte. Afin de pouvoir utiliser une police personnalisée, on utilise `cairo_pdf()` plutôt que `pdf` :

```r
# Exportation en PDF avec gestion de la police
cairo_pdf('densite.pdf',width=6,height=4.7)
par(mar=c(0,0,0,0),family="Myriad Pro",ps=8)

# Tracé de la carte
plot(frontieres, col="#FFFFFF")
plot(europe,     col="#E6E6E6", border="#AAAAAA",lwd=1, add=TRUE)
plot(frontieres, col="#D8D6D4", lwd=6, add=TRUE)
plot(communes,   col=col, border=col, lwd=.1, add=TRUE)
plot(frontieres, col="#666666", lwd=1, add=TRUE)

# Affichage de la légende
legend(-10000,6387500,fill=attr(leg, "palette"),
    legend=names(attr(leg,"table")),
    title = "Densité en hab/km² :")

dev.off()
```

[![Densité de population en 2013]({{site.base}}/medias/carto/densite.jpg)]({{site.base}}/medias/carto/densite.pdf)

## Coloration d'une donnée externe : le revenu médian
En réalité, nous serons plutôt amenés à tracer des données issues d'autres fichiers. Nous allons ici représenter le revenu fiscal médian par unité de consommation ([mis à disposition par l'INSEE](http://www.insee.fr/fr/themes/detail.asp?reg_id=99&ref_id=base-cc-rev-fisc-loc-menage)). À l'aide d'un tableur, [nous remettons ce fichier en forme au format CSV]({{site.base}}/medias/carto/revenus.csv).

### Lecture et correction des données
On lit ce fichier, puis on fait correspondre les données grâce à l'identifiant des communes. Malheureusement, les données sont manquantes pour plus de 5<span style="white-space:nowrap">&thinsp;</span>000 communes, en raison du secret fiscal. "Trichons" pour améliorer le rendu général en affectant à ces communes le revenu médian du canton, fournit dans le même fichier et [remis en forme au format CSV]({{site.base}}/medias/carto/cantons.csv) :




```r
# Lecture des données communales
revenus <- read.csv('csv/revenus.csv')
communes <- merge(communes, revenus, by.x="INSEE_COM", by.y="COMMUNE")

# Lecture des données cantonales
cantons  <- read.csv('csv/cantons.csv')

# Jointure des données
communes <- merge(communes, cantons, by="CANTON", all.x=TRUE)

# Affectation de la moyenne cantonale aux communes sans données
communes$REVENUS[is.na(communes$REVENUS)] <- communes$REVENUC[is.na(communes$REVENUS)]
```

### Échelle de couleur
On génère alors les échelles de couleurs et la légende :

```r
col <- findColours(classIntervals(
            communes$REVENUS, 100, style="quantile"),
            smoothColors("#FFFFD7",98,"#F3674C"))

leg <- findColours(classIntervals(
            round(communes$REVENUS,0), 4, style="quantile"),
            smoothColors("#FFFFD7",2,"#F3674C"),
            under="moins de", over="plus de", between="–",
            cutlabels=FALSE)
```

### Traçage
Il ne reste alors qu'à tracer la carte :

```r
cairo_pdf('revenus.pdf',width=6,height=4.7)
par(mar=c(0,0,0,0),family="Myriad Pro",ps=8)

plot(frontieres, col="#FFFFFF")
plot(europe,     col="#F5F5F5", border="#AAAAAA",lwd=1, add=TRUE)
plot(frontieres, col="#D8D6D4", lwd=6, add=TRUE)
plot(communes,   col=col, border=col, lwd=.1, add=TRUE)
plot(frontieres, col="#666666", lwd=1, add=TRUE)

legend(-10000,6337500,fill=attr(leg, "palette"),
    legend=gsub("\\.", ",", names(attr(leg,"table"))),
    title = "Revenu médian par UC :")

dev.off()
```

[![Revenu fiscal médian par unité de consommation par commune en 2010]({{site.base}}/medias/carto/revenus.jpg)]({{site.base}}/medias/carto/revenus.pdf)



## Traçage de données cartographiques : le réseau routier

Nous pouvons également ajouter des données cartographiques à nos cartes : villes, zones urbaines, fleuves, forêts, relief... Nous allons ici tracer le réseau routier, grâce à [Route 500](http://professionnels.ign.fr/route500) publié par l'IGN :

```r
routes <- readOGR(dsn="shp/geofla",  layer="TRONCON_ROUTE")

local     <- routes[routes$VOCATION=="Liaison locale",]
principal <- routes[routes$VOCATION=="Liaison principale",]
regional  <- routes[routes$VOCATION=="Liaison r\xe9gionale",]
autoroute <- routes[routes$VOCATION=="Type autoroutier",]

cairo_pdf('routes.pdf',width=6,height=4.7)
par(mar=c(0,0,0,0),family="Myriad Pro",ps=8)

plot(frontieres,  col="#FFFFFF")
plot(europe,      col="#F5F5F5", border="#AAAAAA",lwd=1, add=TRUE)
plot(frontieres,  col="#D8D6D4", lwd=6, add=TRUE)
plot(departements,col="#FFFFFF", border="#FFFFFF",lwd=.7, add=TRUE)
plot(local,       col="#CBCBCB", lwd=.1, add=TRUE)
plot(principal,   col="#CCCCCC", lwd=.3, add=TRUE)
plot(regional,    col="#BBBBBB", lwd=.5, add=TRUE)
plot(autoroute,   col="#AAAAAA", lwd=.7, add=TRUE)
plot(frontieres,  col="#666666", lwd=1, add=TRUE)

dev.off()
```

[![Réseau routier français en 2013]({{site.base}}/medias/carto/routes.jpg)]({{site.base}}/medias/carto/routes.pdf)




## Carte du monde vierge

### Lecture des données cartographiques

Nous chargeons ici les fichiers shapefiles de [Natural Earth](http://www.naturalearthdata.com/downloads) à l'échelle 110m (très suffisante à notre échelle) contenant les pays, la grille latitude/longitude, et une boîte pour entourer le planisphère :

```r
# Lecture des fichiers shapefiles
pays   <- readOGR(dsn="shp/ne/cultural",layer="ne_110m_admin_0_countries")
grille <- readOGR(dsn="shp/ne/physical",layer="ne_110m_graticules_10")
boite  <- readOGR(dsn="shp/ne/physical",layer="ne_110m_wgs84_bounding_box")
```

### Projection et traçage

Nous utiliserons ici la projection _[Winkel Tripel](http://fr.wikipedia.org/wiki/Projection_de_Winkel-Tripel)_, qui est l'une des plus esthétiques pour représenter le planisphère :

```r
# Projection en Winkel Tripel
pays   <- spTransform(pays,CRS("+proj=wintri"))
boite  <- spTransform(boite,  CRS("+proj=wintri"))
grille <- spTransform(grille, CRS("+proj=wintri"))

# Tracé du planisphère
pdf('monde.pdf',width=10,height=6) # Exportation en PDF
par(mar=c(0,0,0,0))                # Marges nulles

plot(boite, col="white",    border="grey90",lwd=1)
plot(pays,  col="#E6E6E6",  border="#AAAAAA",lwd=1, add=TRUE)
plot(grille,col="#CCCCCC33",lwd=1, add=TRUE)

dev.off()                          # Enregistrement du fichier
```

[![Carte du monde projetée en Winkel Tripel]({{site.base}}/medias/carto/monde.jpg)]({{site.base}}/medias/carto/monde.pdf)


## Coloration d'une donnée : l'indice de développement humain

L'utilisation la plus fréquente de ce type de carte consiste à colorer chaque pays selon une donnée. Traçons par exemple l'IDH, que le Programme de développement des nations unies propose au [format CSV]({{site.base}}/medias/carto/hdi.csv). La démarche est identique à celle utilisée pour tracer le revenu en France :

```r
# Lecture des données et jointure avec les pays
idh  <- read.csv('csv/idh.csv')
pays <- merge(pays, idh, by.x="iso_a3", by.y="Abbreviation")
# Conversion de l'IDH en valeur numérique
pays$idh <- as.numeric(levels(pays$X2012.HDI.Value))[pays$X2012.HDI.Value]

# Génération de l'échelle de couleurs et affectation
col <- findColours(classIntervals(pays$idh, 100, style="pretty"),
                       smoothColors("#ffffe5",98,"#00441b"))

# Affectation d'un gris clair pour les données manquantes
col[is.na(pays$idh)] <- "#DDDDDD"

# Génération de la légende
leg <- findColours(classIntervals(round(pays$idh,3), 7, style="pretty"),
                       smoothColors("#ffffe5",5,"#00441b"),
                       under="moins de", over="plus de", between="–", cutlabels=FALSE)

# Tracé
cairo_pdf('idh.pdf',width=10,height=6)
par(mar=c(0,0,0,0),family="Myriad Pro",ps=8)

plot(boite, col="white", border="grey90",lwd=1)
plot(pays,  col=col, border=col,lwd=.8, add=TRUE)
plot(grille,col="#00000009",lwd=1, add=TRUE)

legend(-15000000,-3000000,fill=attr(leg, "palette"),
    legend=gsub("\\.", ",", names(attr(leg,"table"))),
    title = "IDH en 2012 :")
dev.off()
```


[![L'indice de développement humain (IDH) dans le monde]({{site.base}}/medias/carto/idh.jpg)]({{site.base}}/medias/carto/idh.pdf)

## Représentation en cercles : les villes les plus peuplées

### Lecture des données
La population de plusieurs des principales villes mondiales est fournie par [Natural Earth](http://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-populated-places/) :

```r
# Chargement du shapefile
villes <- readOGR(dsn="shp/ne/cultural",layer="ne_110m_populated_places")
villes <- spTransform(villes,  CRS("+proj=wintri"))
```

### Calcul des rayons
Nous allons représenter cette donnée à l'aide de cercles. Afin que l'interprétation du lecteur ne soit pas faussée, la population doit être proportionnelle à l'aire des cercles, et non à leur rayon ; on calcule donc ce rayon comme étant la racine carré de la population :

```r
# Calcul du rayon des cercles
villes$rayon <- sqrt(villes$POP2015)
villes$rayon <- villes$rayon/max(villes$rayon)*3
```

### Traçage
On trace alors le graphique :

```r
# Tracé du planisphère avec des cercles
pdf('villes.pdf',width=10,height=6)
par(mar=c(0,0,0,0))

plot(boite, col="white",    border="grey90",lwd=1)
plot(pays,  col="#E6E6E6",  border="#AAAAAA",lwd=1, add=TRUE)
points(villes,col="#8D111766",bg="#8D111766",lwd=1, pch=21,cex=villes$rayon)
plot(grille,col="#CCCCCC33",lwd=1, add=TRUE)

dev.off()
```

[![Carte du monde présentant la population des principales villes]({{site.base}}/medias/carto/villes.jpg)]({{site.base}}/medias/carto/villes.pdf)


## Représentation de données cartographiques : aires urbaines

[Natural Earth](http://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-urban-area/) fournit des données représentant les principales aires urbaines, mesurées à l'aide d'un satellite. Chargeons [ces données](http://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-urban-area/) et traçons-les pour changer avec des couleurs qui rappellent les lumières noctures :

```r
urbain  <- readOGR(dsn="shp/ne/cultural",layer="ne_10m_urban_areas")
urbain <- spTransform(urbain, CRS("+proj=wintri"))

pdf('urbain.pdf',width=10,height=6)
par(mar=c(0,0,0,0))
plot(boite, col="#000000",    border="#000000",lwd=1)
plot(pays,  col="#000000",  border="#000000",lwd=1, add=TRUE)
plot(urbain,  col="#FFFFFF",  border="#FFFFFF66",lwd=1.5, add=TRUE)

dev.off()
```

[![Carte du monde projetée en Winkel Tripel]({{site.base}}/medias/carto/urbain.jpg)]({{site.base}}/medias/carto/urbain.pdf)
