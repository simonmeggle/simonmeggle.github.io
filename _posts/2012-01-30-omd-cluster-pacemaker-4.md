---
layout: post
title:  "Nagios/OMD-Cluster mit Pacemaker/DRBD Teil 4"
date:   2012-01-30 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-4/
excerpt: Bau eines hochverfügbaren Monitoring-Systems
---


### Teil 4 – Einrichtung von OMD als Cluster-Ressource

Im letzten Teil dieses Tutorials haben Sie die Ressourcen definiert, die
OMD zum Betrieb benötigt: Service-IP-Adresse, Apache, DRBD, Mount des
DRBD-Devices, sowie der Ping zur Berechnung des Scores, anhand dessen
der Cluster ein Schwenk der Resourcen auf einen anderen Node beschließen
kann. Wenden wir uns nun OMD selbst zu. Unser Ziel ist es, nicht OMD mit
all seinen Sites als Ressource starten zu lassen (hierzu müssten wir ja
nur das LSB-initscript verwenden), sondern die einzelnen Sites. Jede
Site soll für Pacemaker als eigene Ressource start-/stopp/-überwachbar
sein.

#### OMD-Autostart deaktivieren

Das auf beiden Nodes installierte init-Script von OMD würde beim Start
versuchen, sofort alle definierten Sites zu starten. Die Sites sind im
Cluster jedoch eine *Ressource*, über die einzig der CRM von Pacemaker
walten soll. Deshalb ist der OMD-Autostart *auf beiden Nodes* zu
unterbinden:

{% highlight bash %}

root@nagios1:~# echo "AUTOSTART=0" > /etc/default/omd

{% endhighlight %}

Ein anschließender Test bringt die Gewissheit, dass der Start von OMD
per init-Script von nun an nicht mehr möglich ist:

{% highlight bash %}

root@nagios1:~# invoke-rc.d omd start [enter]
OMD autostart disabled, skipping ...

{% endhighlight %}

#### Erzeugen der Symlinks

Auf jedem Node sollte das Verzeichnis von OMD nun so aussehen:

{% highlight bash %}

root@nagios1:/opt/omd# ls [enter]
apache sites versions

{% endhighlight %}

Erklärung zu den Verzeichnissen:

-   **versions** ist das Verzeichnis der lokalen OMD-Installation.
    Dieses bleibt unangetastet.
-   In **apache** wird später pro Site eine Konfigurationsdatei
    angelegt, die der globale Apache einliest, um mittels mod_proxy die
    eingehenden Requests zur richtigen Site, sprich: zu dem Apache
    zuordnen zu können, der als eigene Instanz für die Site gestartet
    wurde.
-   **sites** ist das Verzeichnis, welches pro angelegter OMD-Site ein
    Unterverzeichnis beherbergt.

Zunächst muss auf *beiden* Nodes die testhalber gestartete OMD-Site
*siteA* wieder gestoppt werden:

{% highlight bash %}

omd stop siteA

{% endhighlight %}

Ggf. muss noch das tmpfs der Site von Hand jeweils ausgehängt werden:

{% highlight bash %}

umount tmpfs

{% endhighlight %}

#### Anpassungen auf dem DRBD-Primary-Node

Auf dem DRBD-**Primary** (also auf dem Node, wo derzeit das DRBD-Blockdevice unter
`/mnt/omddata` gemountet ist, hier: **Node2**) werden beiden zuletzt genannten
Verzeichnisse *apache* und *sites* nun ins DRBD verschoben (dies sind
die Daten, die sich beide Nodes „teilen“ sollen, und an deren Stelle
Softlinks erzeugt, die an die neue Position zeigen:

{% highlight bash %}
root@nagios2:# cd /opt/omd/
root@nagios2:/opt/omd# mv apache/ /mnt/omddata/
root@nagios2:/opt/omd# ln -s /mnt/omddata/apache/ apache
root@nagios2:/opt/omd# mv sites/ /mnt/omddata/
root@nagios2:/opt/omd# ln -s /mnt/omddata/sites/ sites
root@nagios2:/opt/omd# ls -la
  insgesamt 12
  drwxr-xr-x 3 root root 4096 2011-04-28 17:21 .
  drwxr-xr-x 4 root root 4096 2011-04-28 12:35 ..
  lrwxrwxrwx 1 root root 20 2011-04-28 17:21 apache -> /mnt/omddata/apache/
  lrwxrwxrwx 1 root root 19 2011-04-28 17:21 sites -> /mnt/omddata/sites/
  drwxr-xr-x 3 root root 4096 2011-04-28 12:35 versions

{% endhighlight %}

Es ist möglich, mehrere Versionen von OMD auf einem Server zu
installieren und damit Sites zu erzeugen. Damit OMD weiß, welche Site
mit welcher OMD-Version gestartet werden soll, existiert in jedem
Site-Verzeichnis einen Symlink auf das entsprechende
OMD-Versionsverzeichnis. Dieser Link ist relativ und zeigt, da wir das
sites-Verzeichnis verschoben haben, momentan nicht mehr an die richtige
Stelle:

{% highlight bash %}

    root@nagios2:/mnt/omddata# tree -L 3
     .
     ├── apache
     │   └── siteA.conf
     └── sites    
         └── siteA        
            ├── bin -> version/bin        
            ├── etc        
            ├── include -> version/include        
            ├── lib -> version/lib        
            ├── local        
            ├── share -> version/share        
            ├── tmp        
            ├── var        
            └── version -> ../../versions/0.46

{% endhighlight %}

Deshalb legen wir unterhalb von `/mnt/omddata` ein Verzeichnis
*versions* an, in welchem wir pro installierter OMD-version einen
Symlink erzeugen, welcher wieder auf das OMD-Installationsverzeichnis
zeigt:

{% highlight bash %}

root@nagios2:# cd /mnt/omddata [enter]
root@nagios2:/mnt/omddata# cmkdir versions [enter]
root@nagios2:/mnt/omddata# ln -s /opt/omd/versions/0.46 versions/0.46 [enter]

{% endhighlight %}

#### Anpassungen auf dem DRBD-Secondary-Node

Auf dem DRBD-**Secondary** (also dem Node, auf dem das DRBD-Device im Status
"secondary" ist, hier: **Node1**) löschen wir die Verzeichnisse, die wir auf dem
Master-Node ins DRBD-verschoben haben und legen ebenfalls Softlinks an,
die ins (auf diesem Node nicht gemountete) DRBD zeigen:

{% highlight bash %}

root@nagios1:~# cd /opt/omd [enter]
root@nagios1:/opt/omd# rm -rf apache [enter]
root@nagios1:/opt/omd# ln -s /mnt/omddata/apache/ apache [enter]
root@nagios1:/opt/omd# rm -rf sites [enter]
root@nagios1:/opt/omd# ln -s /mnt/omddata/sites/ sites [enter]
root@nagios1:/opt/omd# ls -la [enter]
  insgesamt 12
  drwxr-xr-x 3 root root 4096 2011-04-28 17:21 .
  drwxr-xr-x 4 root root 4096 2011-04-28 12:35 ..
  lrwxrwxrwx 1 root root 20 2011-04-28 17:21 apache -> /mnt/omddata/apache/
  lrwxrwxrwx 1 root root 19 2011-04-28 17:21 sites -> /mnt/omddata/sites/
  drwxr-xr-x 3 root root 4096 2011-04-28 12:35 versions

{% endhighlight %}

#### OMD OCF-Agent

Wie eingangs beschrieben, benötigen wir nun eine Möglichkeit, einzelne
OMD-Sites vom Cluster verwalten (start/stop/monitor) zu lassen.
Hierzu habe ich einen eigenen OCF-Agent geschrieben, welcher den
sitename als Shellvariablen-Argument entgegennimmt. Für *start* und
*stop* der Site werden intern die bekannten Kommandos verwendet;
*monitor* wertet das Endresultat des Kommandos `omd status [sitename]`
aus.

Im Verzeichnis für die Ressource Agents legen wir uns nun auf *beiden*
Nodes jeweils einen eigenen Provider an, der ganz einfach durch ein
neues Verzeichnis neben `linbit`, `pacemaker` und `heartbeat`
repräsentiert wird:

{% highlight bash %}

root@nagios1:/usr/lib/ocf/resource.d# mkdir myprovider

{% endhighlight %}

Laden Sie sich den [OCF-Agenten “OMD”](http://blog.simon-meggle.de/wp-content/uploads/2011/05/OMD)
herunter (z.b. mit wget), entfernen Sie die Endung “.sh”.
Kopieren Sie nun den Agenten in das neu erstellte Agenten-Verzeichnis:

{% highlight bash %}

root@nagios1:/usr/lib/ocf/resource.d# cp -p /root/OMD myprovider/

{% endhighlight %}

Ein erster Trockentest auf der Shell des DRBD-*Master*-Nodes (nur dort,
weil auf dem anderen Node die Verzeichnisse sites und apache nicht
zugreifbar sind!):

{% highlight bash %}

root@nagios2:~# cd myprovider
root@nagios2:# export OCF_ROOT=/usr/lib/ocf
root@nagios2:# export OCF_RESKEY_site=siteA
root@nagios2:# ./OMD monitor
  OMD[30291]: DEBUG: OMD site siteA is stopped.
  OMD[30291]: DEBUG: default monitor : 7
root@nagios2:# ./OMD start
  OMD[31381]: DEBUG: OMD site siteA is stopped.
  OMD[31381]: INFO: Starting OMD site siteA...
  Creating temporary filesystem...OK
  Starting dedicated Apache for site siteA... .OK.
  Starting rrdcached...OK
  Starting npcd: done.
  Starting nagios... OK.
  Initializing Crontab done.
  OMD[31381]: DEBUG: default start : 0
root@nagios2:# ./OMD monitor
  OMD[31790]: DEBUG: OMD site siteA is running properly.
  OMD[31790]: DEBUG: default monitor : 0

{% endhighlight %}

Testen Sie nun, ob Sie siteA auf dem Master-Node öffnen können:
[http://nagios1/siteA](http://nagios1/siteA)
 Nun können wir siteA als Pacemaker-Ressource definieren:

{% highlight bash %}

crm(live)configure# primitive pri_omd_siteA ocf:myprovider:OMD
 op monitor interval="10s" timeout="20s" [enter]
 op start interval="0s" timeout="90s" [enter]
 op stop interval="0s" timeout="100s"  [enter]
 params site="siteA" [enter]
crm(live)# commit [enter]

{% endhighlight %}

Ein abschließender commit sollte auch die OMD-Site siteA in der GUI zum
Vorschein bringen.

#### Anpassungen am rrdcached

Sofern nicht anders konfiguriert, verwendet jede OMD-Site eine eigene
Instanz des RRD Caching Daemons. Der Daemon RRDCacheD empfängt
Aktualisierungen für existierende RRD-Dateien, sammelt diese und
schreibt die Aktualisierungen zeitversetzt weg. Der Daemon wurde für
große Installationen geschrieben, welche häufig in E/A-Probleme laufen.
RRDCacheD soll diese Probleme mildern.

 Im Cluster ist ein guter Kompromiss zu treffen zwischen Caching der
Daten und rechtzeitigem Schreiben aufs DRBD-Device – schließlich könnten
die wertvollen Daten im Cache durch einen plötzlichen Ausfall des
aktiven Knotens für immer verloren gehen, weil sie nicht mehr
rechtzeitig den Weg aufs DRBD-Device (und damit in die Replikation)
finden.

 Aus diesem Grund ist es ratsam, die Timing-Werte des rrdcacheD in jeder
geclusterten Site etwas straffer zu ziehen:

{% highlight bash %}

root@nagios2:# vim /opt/omd/sites/[sitename]/etc/rrdcached.conf
# Data is written to disk every TIMEOUT seconds. If this option is
# not specified the default interval of 300 seconds will be used.
#TIMEOUT=3600
TIMEOUT=180

# rrdcached will delay writing of each RRD for a random
# number of seconds in the range [0,delay). This will avoid too many
# writes being queued simultaneously. This value should be no
# greater than the value specified in TIMEOUT.
#RANDOM_DELAY=1800
RANDOM_DELAY=90

# Every FLUSH_TIMEOUT seconds the entire cache is searched for old
values
# which are written to disk. This only concerns files to which
# updates have stopped, so setting this to a high value, such as
# 3600 seconds, is acceptable in most cases.
#FLUSH_TIMEOUT=7200
FLUSH_TIMEOUT=360

{% endhighlight %}

Danach nur noch die Konfiguration des rrdcached reloaden:

{% highlight bash %}

root@nagios2:# omd reload [sitename] rrdcached [enter]

{% endhighlight %}

Damit ist die Einrichtung der Ressourcen abgeschlossen. Im nächsten Teil
wenden wir uns den Constraints zu, mit denen Beziehungen und
Abhängigketen abbilden.

[Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 1 (Installation der
Nodes)](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil1/)

 [Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 2 (Konfiguration der
Pakete)](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-2/)

 [Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 3 (Einrichtung der
Clusterressourcen)](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-3/)

 [Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 4 (OMD-Sites als
Clusterressource)](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-4/)

 [Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 5
(Constraints)](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-5/)

 [Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 6
(Besonderheiten)](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-6/)
