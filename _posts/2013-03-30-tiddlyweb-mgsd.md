---
layout: post
title: "TiddlyWeb – TiddlyWiki und mGSD im Netz"
date:   2013-03-30 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/tiddlyweb-tiddlywiki-und-mgsd-im-netz/
---



Einleitung
==========

Wohl jeder TiddlyWiki-Anwender kennt das Problem: wie kann ich von
mehreren Rechnern aus mein TiddlyWiki bearbeiten? Für den Hausgebrauch
bieten sich hier zwei Lösungswege an, die jeweils auch schnell umgesetzt
sind:

-   **USB-Stick:** Die Wiki-Datei wird auf einem USB-Stick
    abgespeichert, der einfach “mitgenommen” wird. *Vorteil*: Das
    Problem der Synchronisierung stellt sich gar nicht erst. *Nachteil*:
    ein solcher mobilder Datenträger ist physischen Einflüssen
    ausgesetzt (Schäden aller Art, Vergessen, Verlieren, …) und muss
    entsprechend artig gesichert werden.
-   **Dropbox:** Die Wiki-Datei wird in einen Dropbox-Cloudspeicher
    verschoben. Eine Änderung am Wiki stößt automatisch eine
    Synchronisation in die Cloud an, von aus die Datei wiederum an alle
    anderen Geräte heruntergeladen wird. *Vorteil*: die Datei ist
    automatisch überall aktuell und wird zudem auch noch versioniert
    vorgehalten – da ist das Backup inclusive. *Nachteil:* Jedes
    TiddlyWiki zwar nur die geänderten Tiddler ins Wiki-File
    wegschreibt, Dropbox hingegen aber lediglich eine Änderung auf
    File-Ebene erkennt (klar, was soll Dropbox von Tiddlern verstehen…)
    und jeweils die komplette Datei in die Cloud lädt. Es reicht also,
    einen Buchstaben eines Tiddlers zu ändern, um Dropbox ein knappes MB
    in die Cloud zu schieben.

Ich verwende seit mehreren Jahren beruflich und privat
[mGSD](http://mgsd.tiddlyspot.com/#mGSD "mGSD")
(‘[Getting Things
Done](http://www.davidco.com/ "Getting Things Done")-System
auf TiddlyWiki-Basis; eigener Artikel hierzu folgt), welches ich über
die zweite Lösung, also Dropbox, auf allen Arbeitsstationen synchron
gehalten habe.

Meine bessere Hälfte ist seit ca. zwei Jahren ebenfalls vom
GTD/mGSD-Fieber erfasst und verwendet es wie ich beruflich und privat;
so sehr die Trennung unserer beruflichen Aufgabenplaner Sinn macht, so
enttäuschend war die Erkenntnis, im privaten Bereich keine Möglichkeit
zu haben, übers Web an einem gemeinsamen mGSD arbeiten zu können.

*Doch, es gibt sie.* Ich habe sie wahrscheinlich nur viel zu spät
entdeckt. Die Lösung heißt
[TiddlyWeb](http://tiddlyweb.com/).
In diesem Tutorial möchte ich aufzeigen, wie ein TiddlyWiki (+ Derivate)
auf einem Debian/Ubuntu-System mit dem Webserver CherryPy im Netz
betrieben werden kann, inclusive Authentifizierung und Datensicherung.
Wie alle meine Tutorials beginnt auch dieses “bei null”, d.h. alles was
Sie brauchen ist eine solche Linux-Maschine mit Internetzugang.

Was ist Tiddlyweb?
==================

Sehen wir uns zunächst an, wie der Zugriff auf ein herkömmliches
TiddlyWiki erfolgt:

Die TiddlyWiki-Datei wird vom Browser über das *lokale Filesystem*
geöffnet; sämtliche im Wiki enthaltenen Tiddler sind in dieser Datei
enthalten und werden von dort geladen. Ebenso verhält es sich beim
Speichern: die Änderungen am Wiki werden wieder zurück in die auf dem
lokalen Filesystem liegende html-Datei gespeichert; für Sync-Dienste wie
z.b. Dropbox ist das wie oben erwähnt Grund genug, die *komplette Datei*
(als kleinste Informationseinheit) zu synchronisieren:

[![](TiddlyWeb%20-%20TiddlyWiki%20und%20mGSD%20im%20Netz-Dateien/tiddlywiki.png "tiddlywiki")](http://blog.simon-meggle.de/wp-content/uploads/2012/12/tiddlywiki.png)

Gemeinsames Arbeiten an einem über Dropbox gesharten TiddlyWiki kann nur
schiefgehen. User A müsste bereits vor dem Öffnen des Wikis immer
sicherstellen, dass User B nicht daran arbeitet. Ansonsten gilt: je
nachdem, wer eher mal auf “save changes” klickt, hustet die inzwischen
vom anderen im Wiki geleistete Arbeit vom Tisch.

*TiddlyWeb* setzt genau hier an, indem es den Content eines TiddlyWikis
nicht als ganzes, sondern die einzelnen *Tiddler* verwaltet. Tiddler
sind die kleinste Informationseinheit innerhalb eines TiddlyWikis, die
je nach vergebenen Tags unterschiedliche Funktion und Ausprägungen
haben. Stellen Sie sich Tiddler als “*Universalcontainer*” vor, die
entweder von Ihnen eingegebenen Content enthalten (und mit x-beliebigen
Tags versehen), oder dank spezieller System-Tags vom Wiki intern als
Deskriptoren für Dashboards, CSS-Styles, Menues, etc. verwendet werden.

*TiddlyWeb* ist ein webbasiertes Speichersystem für solchen
“Micro-Content”, wobei jeder Tiddler dank HTTP-API über einen *eigenen
URL* angesprochen und modifiziert werden kann. Tiddler lassen sich in
sog. *Bags* sammeln, welche über Autorisierungs- und Filterfunktionen zu
sog. *Recipes* zusammengefasst werden. In der folgenden Grafik sehen
Sie, dass sich vom Browser aus auf jeden einzelnen Tiddler zugreifen
lässt:

[![](TiddlyWeb%20-%20TiddlyWiki%20und%20mGSD%20im%20Netz-Dateien/tiddlyweb.png "tiddlyweb")](http://blog.simon-meggle.de/wp-content/uploads/2012/12/tiddlyweb.png)

Damit ergeben sich Möglichkeiten, von denen man als (noch-)Benutzer
einer lokalen Instanz nur träumen kann:

-   Speichern von Tiddlern in einem *zugangsgeschützt*en Bereich im Web.
    Der bei TiddlyWeb von Haus aus startbare Mini-Webserver CherryPy
    ermöglicht dies bereits durch Cookie-Authentifizierung. Wer es
    sicherer haben möchte, kann natürlich auch einen anderen Webserver
    mit erweiterten Authentifizierungsmechanismen vorschalten.
-   *Mehrere User* können gleichzeitig an einem Wiki arbeiten, ohne sich
    gegenseitig Änderungen zu überschreiben. Konflikte (wenn tatsächlich
    der gleiche Tiddler bearbeitet werden sollte) werden zwar nicht
    gelöst (a la “git merge”), aber zumindest angezeigt.
-   Tiddler und Wikis gehen in einer *n:m-Beziehung* auf: Ein Wiki hat
    viele Tiddler, ein Tiddler kann von vielen Wikis eingebunden werden.
-   Ein TiddlyWiki kann über die *TiddlyWeb-API* z.b. *dynamisch mit
    Content gefüllt* werden. Ich habe schon einige per Script (z.b. aus
    Konfigurationen heraus) erstellte Dokumentationen gesehen, die
    aufgrund ihrer (zwangsweisen) Linearität leider eine Totgeburt von
    erster Stunde an waren; solchen Content liest niemand. TiddlyWiki
    zählt zu den *non-linearen Wiki*-Systemen und kennt deshalb auch
    kein “Blättern”. Vielmehr wird der in kleine Bestandteile zerlegte
    Content durch Tags intelligent miteinander verbunden- und damit viel
    besser “greifbar”.

Die letzten beiden Punkte sind absolute advanced-Punkte und nicht
Gegenstand dieses Tutorials. Erwähnt werden sollte noch, dass TiddlyWeb
nicht nur für TiddlyWikis incl. seiner Abkömmlinge zu gebrauchen ist.
TiddlySpace, TiddlyHoster und WikiData sind weitere Anwendungen von
TiddlyWeb.

Installation
============

TiddlyWeb wird am einfachsten mit *virtualenv* betrieben, einem Tool,
welches eine vom global installierten Python vollkommen getrennte und
lokale Python-Umgebung erzeugt. Installieren Sie diese (also root):

{% highlight bash %}
root@vserver:\~ \# apt-get update [enter]
\~ \# apt-get install python-virtualenv [enter]
{% endhighlight %}

Erzeugen Sie auf ihrem System einen *User* (hier: tweb), unter dem Ihre
tiddlyweb-Instanz später laufen soll, und wechseln Sie anschließend in
dessen Profil:

{% highlight bash %}

root@vserver:\~ \# adduser tweb [enter]
\~ \# su - tweb [enter]

{% endhighlight %}

Erzeugen Sie im Home-Verzeichnis des Users tweb ein Verzeichnis, in
welchem Sie anschließend die virtualenv-Umgebung aufbauen:

{% highlight bash %}

tweb@vserver:\~\$ mkdir twebroot [enter]
...
tweb@vserver:\~\$ virtualenv twebroot/ [enter]
New python executable in twebroot/bin/python
Installing
distribute.............................................................................................................................................................................................done.
Installing pip...............done.

{% endhighlight %}

Nun wird das virtualenv-Environment gelesen und über *pip* das Paket
*tiddlywebwiki* installiert:

{% highlight bash %}

tweb@vserver:\~\$ cd twebroot [enter]
tweb@vserver:\~/twebroot\$ source bin/activate [enter]
(twebroot)tweb@vserver:\~/twebroot\$ pip install -U tiddlywebwiki
[enter]
...
...
Successfully installed tiddlywebwiki tiddlyweb
tiddlywebplugins.instancer tiddlywebplugins.utils
tiddlywebplugins.wikklytextrender tiddlywebplugins.status
tiddlywebplugins.differ tiddlywebplugins.atom tiddlywebplugins.console
html5lib wikklytext distribute httpexceptor selector simplejson
mimeparse cherrypy tiddlywebplugins.twimport feedgenerator ply boodebr
wsgifront resolver
Cleaning up...

{% endhighlight %}

Nun erzeugen wir unsere TiddlyWiki-Instanz…

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot\$ twinstance mytw [enter]

{% endhighlight %}

…und öffnen die Config-Datei des CherryPy-Webservers, in der wir die
Adresse und den Port hinterlegen, unter dem unser Wiki erreichbar sein
soll. (Hinweis: *tweb* als normaler User ist es nur gestattet, Ports
über 1024 zu öffnen.)

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot\$ cd mytw/ [enter]
(twebroot)tweb@vserver:\~/twebroot/mytw\$ vim tiddlywebconfig.py
[enter]
\# A basic configuration.
\# Run "pydoc tiddlyweb.config" for details on configuration items.

config = {
'system_plugins': ['tiddlywebwiki'],
'secret': '63de751568ad679ae48e369f55bf68f91af15c92',
'twanager_plugins': ['tiddlywebwiki'],
'server_host': {
'scheme': 'http',
'host': 'ip.or.fqdn',
'port': '8080'
}
}

{% endhighlight %}

Starten Sie nun manuell den Webserver…

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/mytw\$ twanager server
Starting CherryPy at http://ip.or.fqdn:8080

{% endhighlight %}

…und rufen Sie im Browser die in der letzten Zeile gezeigte Adresse auf.
Wenn bisher alles geklappt hat, bekommen Sie ein Ergebnis wie dieses
hier:

[![](TiddlyWeb%20-%20TiddlyWiki%20und%20mGSD%20im%20Netz-Dateien/tw_home.png "tw_home")](http://blog.simon-meggle.de/wp-content/uploads/2012/12/tw_home.png)

Zugegeben, das ist noch nicht sonderlich spektakulär. Aber bedenken Sie,
dass Sie momentan bereits direkt mit der API Ihres neuen TiddlyWikis
sprechen!
 Klicken Sie sich weiter durch die Punkte *“recipes” -\> “default” -\>
“Tiddlers in Recipe”*.

[![](TiddlyWeb%20-%20TiddlyWiki%20und%20mGSD%20im%20Netz-Dateien/tw_2_tiddlers1.png "tw_2_tiddlers")](http://blog.simon-meggle.de/wp-content/uploads/2012/12/tw_2_tiddlers1.png)

Nun wird es spannender: klicken Sie sich (am besten in jeweils neuen
Tabs) durch die im Screenshot mit Nummern versehenen Links; Sie bekommen
nun…

1.  bei *wiki* das noch jungfräuliche TiddlyWiki zu Gesicht, bereits
    voll verwendbar. Gratulation
    ![:-)](TiddlyWeb%20-%20TiddlyWiki%20und%20mGSD%20im%20Netz-Dateien/icon_smile.gif)
2.  bei *json* den kompletten Wiki-Inhalt (also alle sechs derzeit
    vorhandenen Tiddler) als JSON-Datenstring.
3.  (bei *html* die gleiche Ansicht)
4.  bei *atom* alle Tiddler als ATOM-Feed
5.  bei *txt* die Namen aller vorhandenen Tiddler

Die Punkte 2-5 sind insbesondere für Entwickler interessant, die das
Wiki nicht “von Hand” anfassen wollen, sondern über Automatismen
lesen/schreiben wollen.

User anlegen
============

Wie Sie sehen, kommen Sie ohne vorherige Anmeldung an das neu erstellte
Wiki, was wir sofort ändern sollten. TiddlyWeb bringt das
Kommandozeilentool *twanager* mit, welches für alle administrativen
Arbeiten am Wiki verwendet wird – unter anderem zum Anlegen von neuen
Usern. (Lassen Sie den manuell gestarteten Server weiterlaufen und
führen Sie die folgenden Befehle am besten in einer neuen Shell aus):

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/mytw\$ twanager adduser admin
adminpassword ADMIN
(twebroot)tweb@vserver:\~/twebroot/mytw\$ twanager adduser simon
simonpassword USER

{% endhighlight %}

Dies legt im users-Verzeichnis Ihres Wiki-Stores pro User eine Datei mit
allen im Kommando eingegebenen Informationen an:

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/mytw\$ tree -L 3
.
├── store
│ ├── bags
│ │ ├── common
│ │ ├── console
│ │ └── system
│ ├── recipes
│ │ └── default
│ └── users
│ . ├── admin
│ . ├── administrator
│ . └── simon
├── tiddlywebconfig.py
├── tiddlywebconfig.pyc
└── tiddlyweb.log

{% endhighlight %}

Löschen Sie nun die User-Datei des default-Administrators, Sie haben ja
nun einen eigenen, der ebenfalls die Rolle ADMIN innehält:

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/mytw\$ rm store/users/administrator

{% endhighlight %}

Recipe ändern
=============

Wie oben beschrieben, bestimmen *Recipes*, welche *User* (bzw. welche
Rollen) welchen *Zugriff* auf welche *bags* haben. Das default Recipe
enthält für die meisten Rollen noch keinen Eintrag, weshalb Sie eben
auch ohne jegliche Anmeldung an alle Inhalte des Wikis kamen. Dies
ändern Sie nun, indem Sie das Recipe wie folgt abändern:

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/mytw\$ vim store/recipes/default
[enter]
desc: standard TiddlyWebWiki environment
policy: {"read": ["R:USER"], "create": ["R:USER"], "manage":
["R:ADMIN"], "accept": [], "write": ["R:ADMIN"], "owner":
"administrator", "delete": ["R:ADMIN"]}

/bags/system/tiddlers
/bags/common/tiddlers

{% endhighlight %}

Führen Sie nun einen Reload auf der Wiki-Seite aus; Sie sollten
stattdessen nun eine Anmeldemaske angezeigt bekommen…

[![](TiddlyWeb%20-%20TiddlyWiki%20und%20mGSD%20im%20Netz-Dateien/tw_auth.png "tw_auth")](http://blog.simon-meggle.de/wp-content/uploads/2012/12/tw_auth.png)

…über die Sie sich nun über den vorhin erstellen User erneut anmelden
können.

Automatischer Start
===================

Nun können Sie den manuell gestarteten CherryPy-Webserver mit Ctrl-C
beenden; in diesem Abschnitt soll der automatische Start des Servers
eingerichtet werden.
 Speichern Sie im Verzeichnis /twebroot/bin das Script start.sh ab,
welches Sie
[hier](http://blog.simon-meggle.de/wp-content/uploads/2012/12/start.sh_1.txt)
zum Download finden, und machen Sie es ausführbar:

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/bin\$ chmod +x start.sh [enter]

{% endhighlight %}

Kontrollieren Sie insbesondere die Variablen *TWROOT_DIR*
(virtualenv-Verzeichnis, s.o.) und *EMAILADDRESS* (Adresse, an die eine
Nachricht gehen soll, wenn der Server nicht läuft) zu Beginn des
Scriptes. Hinterlegen Sie dieses Script nun in der crontab des Users
tweb:

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/bin\$ crontab -e [enter]
...
\# Tiddlywiki Auto-Starter
\* \* \* \* \* \~/twebroot/bin/start.sh mytw

{% endhighlight %}

Sobald Sie den crontab-Editor verlassen haben, sollte innerhalb einer
Minute der CherryPy-Webserver wieder anspringen. Falls nicht, testen Sie
den Aufruf des Scriptes manuell.

Getting Things Done – mGSD TiddlyWiki
=====================================

Wie Sie Ihr TiddlyWiki nun verwenden, ist natürlich Ihr Bier. Wärmstens
empfehlen kann ich *mGSD*. Es bohrt TiddlyWiki zu einem *Projekt- und
Aufgabenplaner* auf, der mich seit über fünf Jahren begleitet und dem
bisher kein anderes Tool Konkurrenz machen konnte; über die Vorzüge des
*Kontext/Area-Taggings* werde ich hier noch separat schreiben. Nun also
gehts zum eigentlichen Kern dieses Tutorials: wie machen Sie aus diesem
TiddlyWiki nun ein mGSD-Wiki?

Laden Sie sich von
[http://monkeygtd.tiddlyspot.com/downloadempty](http://monkeygtd.tiddlyspot.com/downloadempty)
die *leere* Datei des mGSD-Wikis auf Ihren Server:

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/mytw\$ wget -O mGSD_leer.html
http://monkeygtd.tiddlyspot.com/downloadempty

{% endhighlight %}

Mit folgendem Befehl werden die Tiddler des leeren mGSD-Wikis in die
TiddlyWeb-basierte Instanz importiert:

{% highlight bash %}

(twebroot)tweb@vserver:\~/twebroot/mytw\$ twanager twimport common
file:./mGSD_leer.html [enter]

{% endhighlight %}

Der Import dürfte nach wenigen Sekunden abgeschlossen sein. Wenn Sie nun
Ihr TiddlyWiki im Browser reloaden, haben Sie ein **mGSD**, an dem
mehrere User zur gleichen Zeit arbeiten können!  -\> Knüller!

[![](TiddlyWeb%20-%20TiddlyWiki%20und%20mGSD%20im%20Netz-Dateien/mgsd.png "mgsd")](http://blog.simon-meggle.de/wp-content/uploads/2012/12/mgsd.png)

Etwas
[Vorwissen](http://de.wikipedia.org/wiki/Getting_Things_Done "Vorwissen")
zu *Getting Things Done* schadet bei der Verwendung eines so genialen
Tools wie *mGSD* gewiss nicht. Ich möchte es beruflich – und “wir” nun
auch privat nicht mehr missen. In einem der nächsten Artikel werde ich
ein paar nette Hacks zeigen, mit denen man mGSD ganz nach seinem
individuellen Geschmack anpassen kann:

-   Positionieren der Menuüleiste (für Linkshänder
    ![:-P](TiddlyWeb%20-%20TiddlyWiki%20und%20mGSD%20im%20Netz-Dateien/icon_razz.gif)
    )
-   integrieren von Prioritäten-Buttons
-   individuelle Dashboards nach Areas, Projekten und Context
-   ein “TODAY”-Dashboard für starred Items
-   Erweitern der Projekt/Action-Stati um “pending/queued”
-   etc…
