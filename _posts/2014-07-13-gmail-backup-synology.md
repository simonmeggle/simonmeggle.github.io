---
layout: post
title:  "GMail-Backup mit GMVault auf einer Synology Diskstation"
date:   2014-07-13 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/gmail-backup-mit-gmvault-auf-synology-diskstation/
excerpt: sichere, was heilig...
---
![](/assets/gmail-backup-synology/synology.jpg)

In diesem Tutorial möchte ich zeigen, wie ein vollautomatisches Backup eines googlemail-Accounts auf einer Synology Diskstation einzurichten ist. In meinem Beispiel handelt es sich um eine DS-213, wobei das Modell unerheblich ist; viel wichtiger ist eine  aktuelle Firmware.

### Hintergrund

Was geschah? Als [GTD](http://de.wikipedia.org/wiki/Getting_Things_Done)-Anwender verwende ich [ActiveInbox](http://www.activeinboxhq.com/index.php), welches aus einem Googlemail-Account einen vollwertigen Aufgabenplaner macht. ActiveInbox wird als Browser-Plugin installiert und reichtert die von GMail ausgelieferte Seite um eine ganze Reihe nützlicher Funktionen zur Verwaltung von Aufgaben im Zusammenhang mit Emails an. Ein Update von AI – mich schaudert heute noch – sperrte mich nach dem Reload der Seite von GMail aus. Zack, Ende, Aus. GMail war noch so freundlich und meinte, es wurden “verdächtige Zugriffe” auf mein Konto festgestellt, weshalb dieses nun “vorübergehend” gesperrt sei.

Eine kurze Recherche (bei irgendeiner sehr bekannten Suchmaschine…) ergab, dass ich jetzt nur warten konnte: viele andere betroffene berichteten, dass ihr Account irgendwann wieder aktiv geschalten worden war, von wenigen anderen las ich aber auch, dass sie dauerhaft ausgesperrt worden waren. Google bietet keinen Support in solchen Fällen; das Motto hier ist: wirst schon selbst wissen, was Du angestellt hast.

Um es kurz zu machen: ich hatte Glück. Mein Account war nach zwei Tagen plötzlich wieder aktiv. Und AI schob sofort ein Update des Plugins nach. Jedoch war mir dieser Vorfall eine Lehre, weshalb ich mich nach einer Backupmöglichkeit umgesehen habe und auf [GMVault](http://gmvault.org/) gestoßen bin.

GMVault ist ein Open-Source-Tool zur Sicherung von Googlemail-Accounts, welches unter Windows, Mac und Linux läuft. Und da Synology-NAS-Systeme ein Linux mit an Bord haben, lag nichts näher, als nach einer Möglicheit zu suchen, GMVault auf meiner DS214 zum Laufen zu kriegen.

Im Netz kursieren zahlreiche Tutorials zur Installation von GMVault auf Synology-DS. Eines der besten hiervon dürfte das von Matt Stein sein, jedoch stieß ich hier auf Probleme in der Python Virtualenv-Umgebung (die wohl auch Matt hatte), löste sie auf meine Weise und erweiterte sein Shellscript um einige Parameter. Nachfolgend also mein Weg, um GMVault auf einer Synology zu betreiben.

### Vorbereitungen

#### SSH-Zugang

Sofern noch nicht geschehen, muss auf der Diskstation (nachfolgend *DS*) SSH aktiviert werden. Hierzu in der DSM-Systemsteuerung einfach in den Punkt “Terminal (SSH)” wechseln.

Der Login auf der DS sollte dann mit dem gleichen admin-Kennwort wie im Web möglich sein:

FIXME nicht root?
{% highlight bash %}
ssh admin@synds
{% endhighlight %}

#### Backup-Ordner anlegen

Zur Ablage des Backups lege ich mir im DSM einen neuen “Gemeinsamen Ordner” namens “backups-simon” an. Im Filemanager erstelle ich darin den Unterordner “GMail”.

#### Utilities-Ordner anlegen

Für GMVault habe ich einen weiteren gemeinsamen Ordner namens “util” erstellt.

#### Python

Über die Paketverwaltung des DSM nach “Python” suchen. Python3 links liegen lassen und nur Python (2) installieren.

### Installation von GMVault

Zunächst per SSH auf der DS einloggen, sofern noch nicht geschehen:

FIXME root
{% highlight bash %}
ssh admin@synds [enter]
pwd [enter]
/volume1/homes/admin
{% endhighlight %}

Sie befinden sich nun im Home-Verzeichnis des “admin”-Users. Wechseln Sie in das vorhin erstellte “util”-Verzeichnis:

{% highlight bash %}
cd /volume1/util [enter]
{% endhighlight %}

GMVault wird in *virtualenv* betrieben. Virtualenv erzeugt komplett autarke Python-Laufzeitumgebungen, die vom globalen Python unabhängig sind. Laden Sie virtualenv herunter (achten Sie auf die Version 1.10.1 – wie in [diesem](http://stackoverflow.com/questions/23448796/creating-new-virtualenv-1-11-5-failed-with-setuptools-issue) Thread nachzulesen) und entpacken Sie es:

{% highlight bash %}
wget https://pypi.python.org/packages/source/v/virtualenv/virtualenv-1.10.1.tar.gz [enter]
tar xzf virtualenv-1.10.1.tar.gz [enter]
{% endhighlight %}

Nun wird für GMVault eine eigene Laufzeitumgebung aufgebaut. Der Schalter `–no-site-packages` bewirkt, dass dabei keine Packages aus dem System-Bereich angezogen werden:

{% highlight bash %}
python virtualenv-1.10.1/virtualenv.py --no-site-packages gmvault [enter]
...
...
Installing Setuptools...done.
Installing Pip...done.
{% endhighlight %}

Damit beim anschließenden Aufruf von `pip` (= "pip installs packages", Paketmanager für Python) der richtige Installationspfad verwendet wird (nämlich das eben erzeugte virtualenv von GMVault), ist noch das “activate”-Script des virtualenv zu laden:

{% highlight bash %}
cd gmvault/bin [enter]
# Test: Ausgabe von PATH vor dem Aktivieren des virtualenv
echo $PATH [enter]
/sbin:/bin:/usr/sbin:/usr/bin:/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin
# Aktiveren des virtualenv von GMVault
source activate [enter]
echo $PATH [enter]
/volume1/bin/gmvault/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/syno/sbin:/usr/syno/bin:/usr/local/sbin:/usr/local/bin
{% endhighlight %}

Nun wird gmvault über den (lokalen) PIP installiert. Das `–pre`-Flag erlaubt den Zugriff auf Entwicklerversionen und pre-Releases:

{% highlight bash %}
./pip install --pre gmvault
{% endhighlight %}

Das war’s schon. Testen Sie die Ausführung von GMVault, indem Sie sich die Hilfe anzeigen lassen:

{% highlight bash %}
sh gmvault [enter]
{% endhighlight %}

### Anmeldung bei GMail

Zur Anmeldung an GMail wird GMVault initial auf der Kommandozeile gestartet:

{% highlight bash %}
sh gmvault sync --type quick --emails-only --db-dir /volume1/backups-simon/GMail/ your.mail@googlemail.com [enter]
{% endhighlight %}

Da die zwei-Faktor-Authentifizierung von GMail GMVault noch nicht kennt, gibt GMVault einen Link zu Google aus (einen Browser zu starten, wie angeboten funktioniert natürlich nicht, drücken Sie einfach auf Enter). Rufen Sie diesen Link im Browser auf; nach Anmeldung bei Google gelangen Sie zur Aufforderung, GMvault Zugriff auf das Konto zu erlauben. GMvault erhält damit das Zugriffstoken, um auf das Postfach zugreifen zu dürfen.

Beim nochmaligen Aufruf sollte GMVault beginnen, Ihre Mails vom Server zu laden und auf der DS abzulegen. Im nächsten Schritt soll dies noch automatisiert werden.

### Das Backup-Script

Damit GMVault vollautomatisch loslaufen kann (z.b. wöchentlich), hat Matt bereits ein kleines Shell-Script geschrieben, welches ich noch um die drei Parameter Mailadresse, Typ und Backup-Verzeichnis erweitert habe. Damit bleibt das Script generisch und kann für die Sicherung mehrerer Accounts verwendet werden.

Das Script [gmvault-backup.sh](/assets/gmail-backup-synology/gmvault-backup.sh.txt) wird nun heruntergeladen und ausführbar gemacht:

{% highlight bash %}
cd /volume1/util/gmvault [enter]
wget http://blog.simon-meggle.de/assets/gmail-backup-synology/gmvault-backup.sh.txt [enter]
mv gmvault-backup.sh.txt gmvault-backup.sh [enter]
{% endhighlight %}

Testen Sie nun den Aufruf des Shellscriptes:
{% highlight bash %}
/bin/sh /volume1/util/gmvault/gmvault-backup.sh your.mail@googlemail.com full /volume1/backups-simon/GMail/ [enter]
{% endhighlight %}

Wenn Sie im Pfad `/volume1/util/gmvault/log` eine Log-Datei wie
{% highlight bash %}
your.mail@googlemail.com-full-2014-07-13.log
{% endhighlight %}
sehen, scheint alles geklappt zu haben. Obiger Aufruf kann nun im DSM-Webinterface in der Systemsteuerung unter “Aufgabenplanung” als beliebig oft laufender Task eingerichtet werden.
