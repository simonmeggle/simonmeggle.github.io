---
layout: post
title:  "Nagios/OMD-Cluster mit Pacemaker/DRBD Teil 6"
date:   2012-01-30 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-6/
excerpt: Bau eines hochverfügbaren Monitoring-Systems
---


### Teil 6 – Besonderheiten in der Administration


Glückwunsch – wenn Sie bis hier her gekommen sind, kann Sie der Rest
auch nicht mehr schocken. Jetzt ist der Moment, an dem wir auf Dinge
eingehen müssen, in denen sich unser geclustertes OMD von einer
single-server-Installation unterscheidet.

#### Anlegen neuer Sites


Die OMD-Site “siteA” aus den vorangegangenen Teilen dieses Tutorials
funktionierte auf Anhieb auf beiden Nodes. Dies trifft nicht auf
zukünftige Sites zu.

Das Kommando `omd create [site]` legt nicht nur die Verzeichnisse an,
mit denen wir bisher zu tun hatten – pro Site wird auch ein
gleichnamiger User incl Gruppe erzeugt und ein tmpfs in /etc/fstab
eingetragen. Diese Info zwischen den Nodes zu synchronisieren, wäre eine
Fleißaufgabe, um die ich gerne einen Bogen mache – erstens) weil es
einfach kein allzu großer Aufwand ist, sich um diese beiden Punkte noch
zu kümmern, und zweitens) weil das Erstellen von Sites nun wirklich kein
täglich Brot ist.

Wir gehen davon aus, dass Node2 aktiv ist. Nun soll im
Durchmarsch eine neue Site erstellt werden, die ebenfalls vom Cluster
verwaltet werden soll.

Erstellen Sie die neue Site "siteB", starten Sie diese und testen Sie den Zugriff
unter
[http://nagios/siteB/](http://nagios/siteB/):

{% highlight bash %}

root@nagios2:/usr/lib/ocf/resource.d/myprovider# omd create siteB [enter]
  Adding /omd/sites/siteB/tmp to /etc/fstab.
  Created new site siteB with version 0.46.
  Restarting Apache...OK
  Creating temporary filesystem...OK
  Successfully created site siteB.
root@nagios2:# omd start siteB [enter]

{% endhighlight %}

(Preisfrage: warum wird dieser Befehl auf Nagios1 fehlschlagen? )

Wir lesen nun _fstab_ und _passwd_-Dateien aus – notieren Sie sich die
Ausgaben folgender Befehle:

{% highlight bash %}

root@nagios2:# cat /etc/fstab | grep siteB && cat /etc/passwd | grep siteB [enter]
  tmpfs /omd/sites/siteB/tmp tmpfs noauto,user,mode=755,uid=siteB,gid=siteB 0 0
  siteB:x:1002:1002:OMD site siteB:/omd/sites/siteB:/bin/bash

{% endhighlight %}

Zum Erzeugen des tmpfs auf Node1 reicht es, dort die 1. Zeile ans Ende
der Datei _/etc/fstab_ anzuhängen.

Den dortigen User erzeugen Sie incl Gruppe wie folgt – ersetzen Sie GID
und UID mit den IDs, die Sie auf Node2 ausgelesen haben. User und Gruppe
ohne UID/GID explizit anzugeben wird schiefgehen, da Sie sich nicht darauf
verlassen können, dass beide Nodes hierfür automatisch die gleichen
Werte vergeben):

{% highlight bash %}

root@nagios2:# groupadd -g [GID] siteB
root@nagios2:# usermod -aG siteB www-data
root@nagios2:# useradd -u [UID] siteB -d '/omd/sites/siteB' -c 'OMD site siteB' -g siteB -G omd -s '/bin/bash'

{% endhighlight %}

Wechseln Sie in die crm-shell und legen Sie die neue Site als primitive
an (sie sollten die Site danach bereits in der GUI sehen)…

{% highlight bash %}

crm(live)configure# primitive pri_omd_siteB ocf:myprovider:OMD [enter]
op monitor interval="10s" timeout="20s"  [enter]
op start interval="0s" timeout="90s"  [enter]
op stop interval="0s" timeout="100s"  [enter]
params site="siteB" [enter]
crm(live)configure# commit [enter]

{% endhighlight %}

…erstellen Sie colocation und order für siteB…

{% highlight bash %}

crm(live)configure# colocation col_omd_siteB_follows_drbd inf:pri_omd_siteB ms_drbd_omd:Master [enter]
crm(live)configure# order ord_omd_before_siteB inf: group_omd:start pri_omd_siteB:start [enter]
crm(live)configure# commit [enter]

{% endhighlight %}

…und prüfen Sie das Ergebnis in der GUI:

![](/assets/omd-cluster-pacemaker-3/2sites.png)

#### Schlusswort/Ausblick


Ausgehend von diesem Tutorial lassen sich natürlich noch
viele Dinge tunen, dazubauen, überwachen, automatisieren etc. Mein Ziel
war es vielmehr, einen ersten “Durchstich” zu ermöglichen, um von
hier ausgehend selbst weiterzubauen.

Wärmstens empfehlen möchte ich an dieser Stelle das Buch [“Linux
Hochverfügbarkeit”](http://www.amazon.de/Linux-Hochverf%C3%BCgbarkeit-Einsatzszenarien-Praxisl%C3%B6sungen-Computing/dp/3836213397)
von Oliver Liebel, erschienen im Verlag “Galileo Computing”, erschienen
2011.

Wenn Ihnen dieses Tutorial geholfen hat und/oder Sie Anregungen oder
Fragen hierzu haben, freue ich mich auf Ihre Nachricht: Entweder hier
über die Kommentarfunktion oder unter info@simon-meggle.de.

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
