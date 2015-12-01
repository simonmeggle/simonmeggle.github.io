---
layout: post
title:  "OMD-Updates im Pacemaker-Cluster"
date:   2011-06-27 12:58:14 +0100
categories: tutorials
---

Aufbauend auf dem Tutorial [“Nagios/OMD-Cluster mit
Pacemaker/DRBD”](https://web.archive.org/web/20150219092132/http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil1/ "Nagios/OMD-Cluster mit Pacemaker/DRBD")
zeigt dieses Tutorial, wie Sie OMD Site-Updates sicher im Cluster
ausführen.
 Ich habe diesen Prozess in folgende Schritte unterteilt:

1.  Anlegen eines lokalen OMD-root-Ordners “/opt/omd-local” auf beiden
    Nodes; dies macht OMD auch auf dem inaktiven Node lauffähig.
2.  Installation der neuen OMD-Version auf beiden Nodes “neben” die
    aktuell laufende 0.46; die Sites werden dadurch noch nicht
    aktualisiert; Version 0.48 wird zur Default-Version ernannt, mit der
    neu erstellte Sites aufgezogen werden.
3.  Klonen der produktiv laufenden Site vom aktiven Node ins Verzeichnis
    “omd-local” auf dem inaktiven Server
4.  Update des Site-Klones auf dem inaktiven Node
5.  Update der produktiven Site auf dem aktiven Node

Ausgangssituation
=================

Sie haben alle sechs Teile des Tutorials durchgearbeitet und haben nun
zwei Clusternodes (nagios1/nagios2), auf denen OMD in der Version 0.46
läuft. Die OMD-Sites sind immer auf dem Node aufrufbar, auf dem das
DRBD-Device im Status “Master” läuft – soweit, so gut.

Aktuell könnten Sie Updates jedoch nur auf dem Node einspielen, der
gerade der aktive ist, denn auf dem inaktiven Node ist unsere
OMD-Installation nicht überlebensfähig: dort verweisen die Softlinks
“sites” und “apache” unterhalb von /opt/omd/ ins Leere, sprich: an eine
Stelle, an der ja gerade nicht das DRBD-Device gemountet ist. Rechts
sehen Sie den Output von ls -la auf den inaktiven Node mit den rot
eingefärbten “defekten” Softlinks, links auf dem aktiven Node mit
intakten Softlinks:

[![](OMD-Updates%20im%20Pacemaker-Cluster-Dateien/deadlinks.png "deadlinks")](https://web.archive.org/web/20150219092132/http://blog.simon-meggle.de/wp-content/uploads/2011/05/deadlinks.png)

1. Lokale Sites: omd-local
==========================

Um auf dem jeweils inaktiven Node OMD aktualisieren zu können, muss es
auch dort möglich sein,  OMD-Sites starten zu können (natürlich nie
unter der Verantwortung des Clusters, wir werden diese immer von Hand
starten und stoppen, sowie nach dem test sofort wieder löschen). Legen
Sie hierzu auf beiden Nodes folgende Verzeichnisse an:

{% highlight bash %}

mkdir /opt/omd-local
mkdir /opt/omd-local/apache
mkdir /opt/omd-local/sites
mkdir /opt/omd-local/versions

{% endhighlight %}

Das “sites”-Verzeichnis unter “omd-local” ist, genauso wie “sites” im
DRBD, nicht an der Stelle, an der OMD es erwartet (/opt/omd). Damit die
Symlinks darin, die jeweils auf die entsprechende Site-Version innerhalb
von “versions” zeigen, funktionieren, erstellen wir auch hier einen
Symlink:

{% highlight bash %}

ln -s /opt/omd/versions/0.46/ /opt/omd-local/versions/0.46

{% endhighlight %}

Nun wollen wir OMD auf dem inaktiven Node das Laufen beibringen. Wie Sie
im Screenshot oben gesehen haben, sind dort (hier: nagios2) die
Softlinks “/opt/omd/apache” bzw. “sites” defekt, weil das DRBD unter dem
Mount-Verzeichnis /mnt/omddata nicht eingehängt ist und dieses
demzufolge leer ist – was uns aber nicht hindert, hier wiederum
Softlinks “apache” und “sites” abzulegen, die auf unser eben erzeugtes
“omd-local”-Verzeichnis verweisen!

{% highlight bash %}

root@nagios2:\~\# ln -s /opt/omd-local/apache/ /mnt/omddata/apache
root@nagios2:\~\# ln -s /opt/omd-local/sites/ /mnt/omddata/sites

{% endhighlight %}

Wir machen Gebrauch von der Tatsache, dass unter Unix der Inhalt eines
Verzeichnisses (=die Symlinks auf omd-local) ausgeblendet wird, solange
dieses als Mountpunkt verwendet wird (stattdessen werden die
Verzeichnisse aus dem DRBD eingeblendet). Ist der Node inaktiv (=das
DRBD-Device nicht gemountet), werden die Symlinks wieder sichtbar, die
OMD den Weg in das Verzeichnis omd-local zeigen:

{% highlight bash %}

root@nagios2:/mnt/omddata\# ls -la
insgesamt 8
drwxr-xr-x 2 root root 4096 2011-05-27 09:35 .
drwxr-xr-x 4 root root 4096 2011-05-13 09:56 ..
lrwxrwxrwx 1 root root 22 2011-05-27 09:35 apache -\>
/opt/omd-local/apache/
lrwxrwxrwx 1 root root 21 2011-05-27 09:35 sites -\>
/opt/omd-local/sites/

{% endhighlight %}

Sie sollten nun auf nagios2 imstande sein, den Status von OMD abzufragen
(bisher hätten Sie sich eine ordentliche Python-Fehlermeldung
eingefangen, weil /mnt/omddata leer war):

{% highlight bash %}

root@nagios2:/mnt/omddata\# omd status
root@nagios2:/mnt/omddata\#

{% endhighlight %}

Kein Output ist guter Output – es sind ja noch keine lokalen Sites
vorhanden. Erstellen Sie kurzerhand eine Test-Site “foosite” und testen
Sie, ob Sie diese unter
[http://nagios2/foosite](https://web.archive.org/web/20150219092132/http://nagios2/foosite)
aufrufen können:

{% highlight bash %}

root@nagios2:\~\# omd create foosite && omd start foosite

{% endhighlight %}

Stoppen und löschen Sie die Site foosite gleich wieder.

2. Installation von OMD 0.48
============================

OMD ist nun auf beiden Nodes lauffähig – auf dem aktiven ohnehin (mit
den Daten im DRBD), und dank Punkt 1 auch auf dem inaktiven Node (mti
den Daten in /op/omd-local). Wir sind nun bereit, OMD 0.48 auf beiden
Nodes zu installieren. Dieser Vorgang ist relativ unkritisch, werden
doch bestehende Sites nicht angefasst, sondern die neue Version einfach
“neben” die bestehende installiert.
 Laden Sie sich also von der OMD-Seite das
[.deb-Paket](https://web.archive.org/web/20150219092132/http://omdistro.org/attachments/download/96/omd-0.48_0.lucid_i386.deb)
für OMD 0.48 herunter und installieren Sie es auf beiden Nodes mit

{% highlight bash %}

dpkg -i omd-0.48_0.lucid_i386.deb

{% endhighlight %}

Wenn Sie sich anschließend den Verzeichnisinhalt von /opt/omd/versions
ansehen, werden Sie feststellen, dass neben Version 0.46 nun auch ein
Verzeichnis für Version 0.48 existiert. Wir müssen auf dieses nun von
drei Stellen aus verlinken:
 Einmal auf dem aktiven Node aus “sites” in /mnt/omddata:

{% highlight bash %}

ln -s /opt/omd/versions/0.48/ /mnt/omddata/versions/0.48

{% endhighlight %}

Zweimal auf beiden Nodes aus “sites” in /opt/omd-local/:

{% highlight bash %}

ln -s /opt/omd/versions/0.48/ /opt/omd-local/versions/0.48

{% endhighlight %}

(Das ist die Konsequenz davon, dass wir die Sites nicht, wie von OMD
erwartet, unter /opt/omd/sites ablegen, sondern im DRBD, bzw. unter
omd-local).

Angepasstes Dokuwiki?
---------------------

Wenn Sie Dokuwiki mit Templates und/oder Plugins erweitert, bzw.
Änderungen am Layout durch Editieren der CSS-Dateien vorgenommen haben,
ist dieser Abschnitt für Sie wichtig (das gilt auch für
nicht-geclusterte OMD-Installationen und damit evt. die Leser, die vom
Tutorial “[Import von Dokuwiki in eine
OMD-Site](https://web.archive.org/web/20150219092132/http://blog.simon-meggle.de/tutorials/import-von-dokuwiki-in-eine-omd-site/ "Import von Dokuwiki in eine OMD-Site")”
hierher geleitet wurden). Informieren Sie sich vorher anhand der
Dokumentationen der Plugins/Templates, ob diese mit dem Dokuwiki der
neuen OMD-Version zusammenarbeiten.

Die von Ihnen vorgenommenen Änderungen/Erweiterungen finden nicht
Site-spezifisch statt, sondern pro OMD-Version. Für die Site A sieht es
so aus, als wären Plugins und Templates installiert unter

{% highlight bash %}

/opt/omd/sites/siteA/share/dokuwiki/htdocs/lib/

{% endhighlight %}

Wenn Sie diesen Pfad aber von links nach rechts verfolgen, stellen Sie
fest, dass “share” ein Symlink in das installationsverzeichnis der jew.
OMD-Version ist:

{% highlight bash %}

/opt/omd/sites/siteA\# ls -la share [enter]
lrwxrwxrwx 1 siteA siteA 13 2011-05-13 12:51 share -\> version/share
lrwxrwxrwx 1 siteA siteA 19 2011-05-13 12:51 version -\>
../../versions/0.46

{% endhighlight %}

In Wirklichkeit also sind die Dokuwiki-Templates und Plugins innerhalb
einer OMD-0.46-Site   unterhalb dieses Pfades installiert:

{% highlight bash %}

/opt/omd/versions/0.46/share/dokuwiki/htdocs/lib/

{% endhighlight %}

In den Unterverzeichnissen “tpl” und “plugins” finden Sie die Ordner der
jeweils in Ihrer Umgebung installierten Erweiterungen. Was Sie davon in
OMD 0.48 mitnehmen möchten, kopieren Sie *zunächst nur auf dem inaktiven
Node* in

{% highlight bash %}

/opt/omd/versions/0.48/share/dokuwiki/htdocs/lib/

{% endhighlight %}

Die jew. Ordner enthalten z.T. auch Einstellungen der Plugins/Templates,
welche somit gleich übernommen werden.

3. Klonen der Site zum inaktiven Node
=====================================

In unserem Test soll ein Klon von siteA auf dem inaktiven Node
hochgefahren und dort auf Version 0.48 aktualisiert werden. Das Klonen
erledigen wir mit dem Kommando “omd cp [sitename] [newsite]“, wozu siteA
aber zunächst angehalten werden muss. Wer nun mit den Fingern knackt und
“omd stop siteA” eintippt, um sie im nächsten Schritt zu klonen, hat
vergessen, dass wir es nicht mehr “nur” mit OMD alleine, sondern mit
einem OMD-Cluster zu tun haben! Dieser hat dank unseres
[OCF-OMD-Agenten](https://web.archive.org/web/20150219092132/http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-4/)
ein wachsames Auge auf siteA und würde sofort merken, wenn diese nicht
oder nur teilweise läuft und demnach sofort versuchen, die Site neu zu
starten. Deshalb nehmen wir siteA mit folgendem one-shot-Kommando
vorübergehend aus der Verantwortung des Clusters:

{% highlight bash %}

crm resource unmanage pri_omd_siteA

{% endhighlight %}

Beobachten wir derweil die Ausgabe von “crm_mon” – hinter siteA sollte
kurz darauf “(unmanaged)” erscheinen. Jetzt erst können wir mit siteA
tun und lassen, was uns beliebt, der Cluster hat nichts mehr
dreinzureden. Mit folgendem Dreisatz wird siteA angehalten, geclont und
sofort wieder gestartet:

{% highlight bash %}

root@nagios1:/opt/omd/sites\# omd stop siteA && omd cp siteA siteAclone
&& omd start siteA [enter]
Removing Crontab
Stopping nagios.....OK.
Stopping npcd: done.
Stopping rrdcached...waiting for termination...OK
Stopping dedicated Apache for site siteA... .OK.
Copying site siteA to siteAclone...OK
Apache port 5000 is in use. I've choosen 5002 instead.
Updating precompiled host checks for Check_MK...OK
Adding /omd/sites/siteAclone/tmp to /etc/fstab.
Restarting Apache...OK
Starting dedicated Apache for site siteA... .OK.
Starting rrdcached...OK
Starting npcd: done.
Starting nagios... OK.
Initializing Crontab done.

{% endhighlight %}

Damit der Site-Klon auf nagios2 gestartet werden kann, sind folgende
Schritte notwendig:

1.  Kopieren des entspr. Site-Verzeichnisses
2.  Kopieren der entspr. Apache-Config-Datei
3.  Anlegen des Site-Users
4.  Anlegen des tmpfs-Eintrags in /etc/fstab

Schritt 1 und 2 erledigen Sie wie folgt:

{% highlight bash %}

root@nagios1:\# rsync -az /opt/omd/sites/siteAclone
nagios2:/opt/omd-local/sites/ [enter]
root@nagios1:\# rsync -az /opt/omd/apache/siteAclone.conf
nagios2:/opt/omd-local/apache/

{% endhighlight %}

Schritt 3 und 4 können Sie dem Abschnitt [“Anlegen neuer
Sites”](https://web.archive.org/web/20150219092132/http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-6#newsite/ "Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 6")
in Teil 6 meines OMD-Cluster-Tutorials nachlesen.
 Mit “ls -la” im Verzeichnis “/opt/omd-local/sites/” auf dem inaktiven
Node vergewissern Sie sich, dass das Verzeichnis “siteAclone” nun
vollständig “siteAclone” zugeordnet ist. Starten Sie nun den Klon mit
dem bekannten Kommando

{% highlight bash %}

omd start siteAclone [enter]

{% endhighlight %}

und rufen Sie seine Startseite unter
[http://nagios2/siteAclone](https://web.archive.org/web/20150219092132/http://nagios2/siteAclone)
auf. Dort sollten Sie nun Ihre vertraute Nagios/OMD-Umgebung
vorfinden -  jedoch als vollwertigen Klon und damit Testkaninchen fürs
bevorstehende Update:

4. Update des Site-Klones (Test)
================================

Am Testkaninchen “siteAclone” können wir auf dem inaktiven Node nun nach
Belieben testen, ob ein Upgrade von Version 0.46 auf 0.48 funktioniert:

{% highlight bash %}

root@nagios2:\# omd stop siteAclone [enter]
...
root@nagios2:\# omd update siteAclone [enter]
...
...
\* Identical var/nagvis/userfiles/templates/default.login.html
Updating precompiled host checks for Check_MK...OK
root@nagios2:\# omd sites
SITE VERSION
siteAclone 0.48 (default)
root@nagios2:\# omd start siteAclone [enter]

{% endhighlight %}

Es kann sich evt. lohnen, den Site-Clone vor dem Update per “omd cp” zu
sichern; schlägt das Update fehl, müssen Sie hiervon lediglich einen
neuen lokalen Klon erzeugen, anstatt alles nocheinmal per rsync zu
kopieren.
 Prüfen Sie nun, ob die Site nach dem Update fehlerfrei arbeitet.

5. Update der produktiv-Site
============================

Wenn Sie sichergestellt haben, dass die Site korrekt arbeitet, geht es
ans Update der produktiven Sites. (Die Dokuwiki-Template/Plugin-Ordner,
welche Sie evt. in Punkt 2 zum Test auf den inaktiven Node kopiert
haben, kopieren nun analog ins 0.48-Verzeichnis auf dem gleichen Node.)

Führen Sie nun analog zu Schritt 4 das Update von siteA durch – und
denken Sie daran, eine geclusterte Site stets zuerst “unmanagen” (siehe
Punkt 3), bevor sie sie anhalten. Sie führen ansonsten einen eher
aussichtslosen Kampf gegen den Cluster Resource Manager, der die Site
sofort wieder starten will.
 Mathias Kettner hat die Update-Prozedur an sich sehr [detailliert
dokumentiert](https://web.archive.org/web/20150219092132/http://mathias-kettner.de/omd_update.html),
sodass ich mir und Ihnen diese Erklärung hier erspare.

Ausblick/Hinweis
================

Spielen Sie Updates niemals direkt in produktiv-Sites ein, sondern
halten Sie sich stets daran, ein der beschriebenen (oder ähnlichen) Art
und Weise zu testen, testen, testen. Besonderes Augenmerk gilt manuellen
Eingriffen in die OMD-Installation, wie z.b. nachträglich installierte
Addons. Sonst liegt das “Schweizer Taschenmesser OMD” plötzlich in
Einzelteilen vor Ihnen.
