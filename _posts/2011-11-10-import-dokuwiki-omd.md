---
layout: post
title:  "Import von Dokuwiki in eine OMD-Site"
date:   2011-11-10 12:58:14 +0100
categories: tutorials
---

Einleitung
==========

In diesem Tutorial zeige ich, wie Sie ein bereits existierendes Dokuwiki
in eine OMD-Site importieren. Eine allgemeingültige Anleitung hierfür zu
schreiben ist schwierig, da schon die schiere Menge an
Anpassungsmöglichkeiten (CSS, Templates, Plugins, etc…) den Rahmen
sprengen würde. Die folgend genannten Migrations-Punkte beziehen sich
auf eine bei mir produktiv laufende Dokuwiki-Seite, die ich in eine nach
meinem
[Tutorial](https://web.archive.org/web/20150219101314/http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil1/ "Nagios/OMD-Cluster mit Pacemaker/DRBD")
geclusterte OMD-Site “siteB” gezogen und somit – wie Nagios selbst –
hochverfügbar gemacht habe. Natürlich ist das Tutorial auch auf
OMD-Sites anwendbar, die nicht im Cluster laufen.

Ich gehe davon aus, dass das Dokuwiki ihres Quellsystems in der gleichen
Version läuft wie die von OMD mitgelieferte. Falls Ihr Quellsystem älter
sein sollte, können Sie dieses entweder zuerst aktualisieren und dann
die Daten migrieren – oder nach Methode “Augen zu und durch” mit der
Migration gleich einen Versionssprung hinlegen. Wenn Sie die Migration
mit einem Klon der produktiven OMD-Site testen (oder unter omd-local;
weitere Infos hierzu in meinem [Tutorial zu
OMD-Cluster-Updates](https://web.archive.org/web/20150219101314/http://blog.simon-meggle.de/tutorials/omd-updates-im-pacemaker-cluster/ "OMD-Updates im Pacemaker-Cluster")),
können Sie durchaus zu zweiter Methode greifen.
 Wie bei OMD sind auch in Dokuwiki die Nutzerdaten strikt von den
Installationsdateien getrennt, was den Aufwand, unsere kostbaren
Wiki-Pages von “wikiserver” auf die entsprechende OMD-Site zu
transferieren, auf das Kopieren des Ordners “data” reduziert (Dokuwiki
arbeitet mit Flat Files). Genau damit starten wir auch gleich:

Kopieren des “data”-Verzeichnisses
==================================

Zunächst kopieren wir den Ordner “data” (in welchen Dokuwiki die
“beweglichen” Daten ablegt) vom Quellsystem (unser Wiki-Server, den wir
ablösen wollen) auf das Zielsystem (die OMD-Site); der Ordner liegt
üblicherweise unterhalb von “dokuwiki” im Basisverzeichnis des
Webservers (distributionsabhängig). Packen Sie ihn mit “tar” und
kopieren Sie die kostbare Fracht auf den OMD-Server, bzw. den aktiven
OMD-Clusternode, in diesem Beispiel Nagios1:

{% highlight bash %}

wikiserver:\~ \# tar cfz /root/dokuwikidata.tgz
/srv/www/htdocs/dokuwiki/data/ [enter]
wikiserver:\~ \# scp dokuwikidata.tgz nagios1: [enter]

{% endhighlight %}

Wechseln Sie nun auf node1 ins Dokuwiki-Verzeichnis innerhalb der
OMD-Site und benennen Sie zunächst das originale “data” Verzeichnis um.
Danach extrahieren Sie das tgz-File vom Quellsystem und machen den User
“siteB” resp. seine Gruppe zum Eigentümer dieses Verzeichnisses:

{% highlight bash %}

root@nagios1:\~\# cd /omd/sites/siteB/var/dokuwiki/ [enter]
mv data dataORIG [enter]
tar xfz /root/dokuwikidata1.tgz [enter]
chown -R siteB.siteB data [enter]

{% endhighlight %}

Wenn Sie nun die Seite
[http://nagios2/siteB/wiki/doku.php](https://web.archive.org/web/20150219101314/http://nagios2/siteB/wiki/doku.php)
öffnen, sollten Sie bereits den Inhalt des Quellsystems sehen. Machen
wir uns ans Feintuning, dass unser neues OMD-Dokuwiki seinem Vorgänger
möglichst ähnelt.

Template
========

Das aktuelle Wiki benutzt das Template “arctic-mbo”, welches wir auch im
Zielsystem verwenden wollen. Installieren Sie möglichst die gleiche
Version wie im Quellsystem und aktualisieren Sie auf eine evt. neuere
Version erst im Anschluss:

{% highlight bash %}

root@nagios1:\~\# tar xfz arctic-mbo_2011-01-09.tgz -C
/omd/sites/siteB/share/dokuwiki/htdocs/lib/tpl

{% endhighlight %}

Das Template werden wir u.a. im folgenden Abschnitt “Globale
Einstellungen” aktivieren.

Wie Sie die installierten Templates bei einem OMD-Update behalten,
erfahren Sie
[hier](https://web.archive.org/web/20150219101314/http://blog.simon-meggle.de/tutorials/import-von-dokuwiki-in-eine-omd-site#update).

Plugins
=======

Dokuwiki benutzt eine flexible API, welche die Programmierung von
Plugins und somit die Anpassung des Wikis an eigene bzw.
unternehmensrelevante Belange leicht macht. Wer – wie ich in meinem
Beispiel, und höchstwahrscheinlich auch Sie – eine Dokuwiki-Installation
sein Eigen nennt, die mit solchen Plugins erweitert wurde, sollte diese
auch bei der Migration berücksichtigen.
 Dokuwiki-Plugins, welche die Wiki-Syntax erweitern, um z.B. sortierbare
Tabellen darstellen zu können, müssen Sie in jedem Fall auch auf dem
Zielsystem wieder installieren, damit der Wiki-Quelltext auch dort
wieder korrekt dargestellt werden kann. Plugins wie z.B. dw2pdf
(PDF-Export von Wiki-Seiten) erweitern dagegen nur die Funktionalität
des Wikis. Fehlt ein solches Plugin auf dem Zielsystem, steht die
entsprechende Funktion halt nicht zur Verfügung, das ist alles…

Zur Installation der Plugins ziehen Sie am besten die jeweilige
Anleitung des Entwicklers zu Rate, denn jedes Plugin hat so seine
Besonderheiten und muss nach der Installation oft mit einigen Hacks im
Wiki verankert werden. Plugins werden, ebenso wie Templates, pro
OMD-Version gespeichert und gelten somit für alle Sites:

{% highlight bash %}

/opt/omd/sites/siteB/version/share/dokuwiki/htdocs/lib/plugins

{% endhighlight %}

Wie Sie die installierten Plugins bei einem OMD-Update behalten,
erfahren Sie
[hier](https://web.archive.org/web/20150219101314/http://blog.simon-meggle.de/tutorials/import-von-dokuwiki-in-eine-omd-site#update).

(So eine Wiki-Migration ist übrigens ein guter Zeitpunkt, sich von
Plugins wieder zu trennen, die in gutem Willen installiert und doch nie
verwendet wurden…)

Fehlender Plugin-Manager?
-------------------------

Sollte im Admin-Bereich des Zielsystems der Punkt “Plugins verwalten”
fehlen, so entfernen Sie folgende Datei; laden Sie danach die Seite neu:

{% highlight bash %}

root@nagios1:\~\# rm
/opt/omd/sites/siteB/version/share/dokuwiki/htdocs/lib/plugins/plugin/disabled

{% endhighlight %}

CSS-Anpassungen
===============

Auf meinem Quellsystem hatte ich die Farbe des Headers auf ein leichtes
grau-blau geändert; auch solche Änderungen müssen wir händisch im
Zielsystem nachziehen. Die zugehörigen CSS-Dateien liegen, wie Templates
und Plugins, innerhalb der OMD-Installation und sind nur mit einem
Softlink namens “share” zur Site verbunden:

{% highlight bash %}

vim
/opt/omd/versions/0.46/share/dokuwiki/htdocs/lib/tpl/arctic-mbo/arctic_layout.css[enter]

{% endhighlight %}

Wie Sie die CSS-Änderungen bei einem OMD-Update behalten, erfahren Sie
[hier](https://web.archive.org/web/20150219101314/http://blog.simon-meggle.de/tutorials/import-von-dokuwiki-in-eine-omd-site#update).

Globale Einstellungen
=====================

Natürlich läge nichts näher, die Dokuwiki-Konfiguration per diff
abzugleichen. Ich ziehe es vor, die Konfiguration manuell über das
Webinterface abzugleichen.
 Wechseln Sie im Quell- sowie im Zielsystem in den “Admin”-Bereich und
dort in “Configuration Settings” bzw. “Konfiguration”. Gehen sie nun von
Parameter zu Parameter und passen Sie die jeweiligen Werte im Zielsystem
an. Plugins und Templates, welche wir zuvor installiert haben, tauchen
hier nun ggf. mit einer eigenen Config-Section auf.

Authentifizierung
=================

Hier kommen wir zu einem Teil, der ausführlicher erklärt werden sollte.
Wie Sie wissen, legt OMD beim Erstellen einer Site bereits einen User
“omdadmin” an. Sie finden unter “/omd/sites/siteB/etc” eine Datei namens
“htpasswd”, welche vom dedizierten Apache der Site als
Authentifizierungs-Backend benutzt wird. Was darin auf den Usernamen
folgt, ist ein Hash des Passworts “omd”:

{% highlight bash %}

OMD[siteB]:\~\$ cat /opt/omd/sites/siteB/etc/htpasswd
omdadmin:M29dfyFjgy5iA

{% endhighlight %}

Dokuwiki benutzt zur Authentifizierung eine der htpasswd ähnliche Datei
namens “users.auth.php”:

{% highlight bash %}

OMD[siteB]:\~\$ cat /opt/omd/sites/siteB/etc/dokuwiki/users.auth.php
\#
omdadmin:M29dfyFjgy5iA:OMD Admin:admin@example.org:admin,user

{% endhighlight %}

Dass Sie mit den gleichen Zugangsdaten auch auf das Dokuwiki der Site
zugreifen können, ist also kein Zufall – OMD hat die beiden Dateien ganz
einfach mit den (fast) gleichen Benutzerkennungen gefüllt.
 Natürlich werden Sie nicht immer nur mit dem User “omdadmin” arbeiten,
sondern weitere Benutzer anlegen wollen. Bestehende User vom
Dokuwiki-Quellsystem können Sie einfach aus der Datei “users.auth.php”
in die des Zielsystems übernehmen.

Möchten Sie einen neuen user “sepp” anlegen, haben Sie folgende
Möglichkeiten:

einfach: getrennte Backends
---------------------------

Alles bleibt, wie es ist; Sie legen Sepp als User sowohl in der
htpasswd…

{% highlight bash %}

OMD[siteB]:\~\$ htpasswd /opt/omd/sites/siteB/etc/htpasswd sepp [enter]
New password:
Re-type new password:
Adding password for user sepp

{% endhighlight %}

…als auch im der users.auth.php an; verwenden Sie hierzu das Modul
“Benutzerverwaltung” im Adminbereich von Dokuwiki.
 Diese Methode bietet sich an, wenn der Kreis der Dokuwiki-Nutzer ein
wesentlich anderer als der der Nagios-Nutzer ist.

komfortabel: Dokuwiki als User-Backend
--------------------------------------

Für den Fall, dass jeder auf der Site angemeldete User auch Zugriff aufs
Wiki haben soll (den Zugriff auf Seiten/User-Ebene können Sie mit
sogenannten
[ACLs](https://web.archive.org/web/20150219101314/http://www.dokuwiki.org/de:acl)
steuern), bietet sich die zweite Methode an. Dabei wird die Datei
“htpasswd” durch einen Symlink auf die Datei “users.auth.php” von
Dokuwiki ersetzt – mit anderen Worten: User, die Sie über den
komfortablen Usermanager von Dokuwiki anlegen, sind gleichzeitig auch
OMD-User.
 Stoppen Sie zunächst SiteB und wechseln Sie in den Konfigurationsdialog
der Site:

{% highlight bash %}

OMD[siteB]:\~\$ omd stop [enter]
omd config [enter]

{% endhighlight %}

Über den Punkt “DOKUWIKI_AUTH” gelangen Sie in ein neues Fenster:

[![](Import%20von%20Dokuwiki%20in%20eine%20Nagios_OMD-Site-Dateien/omdconfigsiteB.png "omdconfigsiteB")](https://web.archive.org/web/20150219101314/http://blog.simon-meggle.de/wp-content/uploads/2011/06/omdconfigsiteB.png)

Wählen Sie “on”, um Dokuwiki zum zentralen User-Backend zu machen und
beenden sie den Assistenten. Was hat sich nun geändert? Ein
vorher-nachher-Vergleich zeigt es:

{% highlight bash %}

root@nagios2:/opt/omd/sites/siteB/etc\# ls -la htpasswd\* [enter]
-rw-r--r-- 1 siteB siteB 42 2011-06-15 08:43 htpasswd
root@nagios2:/opt/omd/sites/siteB/etc\# omd config siteB [enter]
... [enable Dokuwiki for user management] ...
root@nagios2:/opt/omd/sites/siteB/etc\# ls -la htpasswd\* [enter]
lrwxrwxrwx 1 siteB siteB 23 2011-06-15 09:39 htpasswd -\>
dokuwiki/users.auth.php
-rw-r--r-- 1 siteB siteB 42 2011-06-15 08:43 htpasswd.omd

{% endhighlight %}

htpasswd zeigt fortan als Softlink auf die User-Datei von Dokuwiki; die
originale htpasswd-Datei wurde umbenannt.
 Starten Sie nun wieder SiteB und legen Sie im Admin-Bereich von
Dokuwiki einen neuen User an. Dieser sollte nun auf Dokuwiki (ohnehin)
und auf alle anderen Bereiche der OMD-Site (NagVis, PNP, Thruk…)
zugreifen können. Bedenken Sie jedoch, dass neu angelegte User in der
Grundeinstellung nur die Nagios-Checks sehen, für welche sie auch
benachrichtigt werden. Das sind zu Anfangs – Sie haben’s erraten: keine.

OMD-Updates und Dokuwiki
========================

Wie Sie CSS-Layout-Anpassungen, installierte Plugins und Templates in
einer neue OMD-Version übernehmen, habe ich in meinem Tutorial
[OMD-Updates im
Pacemaker-Cluster](https://web.archive.org/web/20150219101314/http://blog.simon-meggle.de/tutorials/omd-updates-im-pacemaker-cluster#dokuwiki "OMD-Updates im Pacemaker-Cluster")
unter Punkt FIXME beschrieben. Dieser Abschnitt ist auch für
nicht-geclusterte OMD-Installationen gültig.
