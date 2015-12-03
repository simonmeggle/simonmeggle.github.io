---
layout: post
title:  "Nagios/OMD-Cluster mit Pacemaker/DRBD Teil 2"
date:   2012-01-30 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-2/
excerpt: Bau eines hochverfügbaren Monitoring-Systems
---


### Teil 2 – Konfiguration der Pakete


In [Teil
1](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil1/ "Nagios/OMD-Cluster mit Pacemaker/DRBD")
dieses Tutorials haben Sie die beiden Clusternodes mit Ubuntu 10.04
installiert, die Netzwerkkarten eingerichtet und die Pakete installiert,
die im weiteren Verlauf nun konfiguriert werden.

#### DRBD-MC


Auch wenn Sie den Cluster hauptsächlich auf der Kommandozeile
konfigurieren werden, wollen wir dem Cluster mit der [DRBD-MC
(Management Console)](http://oss.linbit.com/drbd-mc/) auf die Finger schauen. Die DRBD-MC wird, wie auch DRBD selbst, von
Linbit HA Solutions (Wien) entwickelt. Ursprünglich als reine DRBD-GUI
gedacht, hat sich die Java-basierte Applikation zu einem echten
Multitalent gemausert und beherrscht die Einrichtung und Verwaltung von
LVM, DRBD und Cluster-Ressourcen. DRBD-MC verbindet sich dabei per ssh
auf die Cluster-Nodes und ist dank Java plattformunabhängig.
Laden Sie sich auf Ihrem Host die neueste jar-Datei herunter starten Sie diese per

{% highlight bash %}

~$ java -jar [Pfad zur jar.Datei]DMC-0.9.2.jar

{% endhighlight %}

#### Corosync Konfiguration

Öffnen Sie nun auf beiden Nodes die Konfigurationsdatei von Corosync und
passen sie die Zeilen so an, wie nachfolgend aufgeführte `corosync.conf`
zeigt.

Totem ist ein zentraler Bestandteil von Corosync – die Nodes tauschen
sich über sog. “Rings” über ihren Status aus. Ändern Sie die
Konfiguration auf *zwei* Interfaces ab. Damit diese einen redundanten Ring
bilden, setzen Sie rrp_mode auf “active”. Die Bindnet-Addresse endet
auf Null, da sie ein Netzwerk bezeichnet!

Ändern Sie auf beiden Nodes die default-Startrichtlinie für Corosync
auf “yes”:

{% highlight bash %}

vim /etc/default/corosync [enter]
# start corosync at boot [yes|no]
START=yes


{% endhighlight %}

(Tipp: sollten Sie im späteren Verlauf feststellen, dass Corosync
ungewöhnlich viel CPU-Load verursacht, checken Sie nochmal die
Interface-Konfiguration der Rings; Fehler hier führen
nachgewiesenermaßen zu solch unerwarteten Fehlern)
 Die Logging-Optionen sind reine Empfehlungen.

{% highlight bash %}

vim /etc/corosync/corosync.conf [enter]
totem {
  version: 2
  token: 3000
  token_retransmits_before_loss_const: 10
  join: 60
  consensus: 5000
  vsftype: none
  max_messages: 20
  clear_node_high_bit: yes
  secauth: off
  threads: 0
  rrp_mode: active

  interface {
    ringnumber: 0
    bindnetaddr: 10.1.1.0
    mcastaddr: 226.94.1.1
    mcastport: 5410
  }
  interface {
    ringnumber: 1
    bindnetaddr: 10.1.2.0
    mcastaddr: 226.94.1.1
    mcastport: 5415
  }
}

amf {
  mode: disabled
}

service {
  # Load the Pacemaker Cluster Resource Manager
  ver: 0
  name: pacemaker
}

aisexec {
  user: root
  group: root
}

logging {
  fileline: off
  to_stderr: yes
  to_logfile: yes
  logfile: /var/log/corosync.log
  to_syslog: yes
  syslog_facility: daemon
  debug: on
  timestamp: on
  logger_subsys {
    subsys: AMF
    debug: off
    tags: enter|leave|trace1|trace2|trace3|trace4|trace6
  }
}

{% endhighlight %}

Starten Sie nun die DRBD-MC und klicken Sie auf den “Host Wizard”.

[![Hostwizard](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%202%20-%20Simon%20Meggle-Dateien/hostwiz.jpg "Hostwizard")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/hostwiz.jpg)
 Geben Sie den Namen des ersten Nodes (“nagios1″) an; DRBD-MC wird Sie
nach dem root-Passwort fragen und sich auf den Node verbinden. Nachdem
Systeminformationen abgefragt sind, sollten Sie dank vorheriger
Installation aller Pakete den folgenden Hinweis sehen:

[![DRBD-MC-allinstalled](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%202%20-%20Simon%20Meggle-Dateien/allinstalled.jpg "allinstalled")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/allinstalled.jpg)
 Nachdem Sie diesen Schritt mittels “Add Another Host” für den Node
“nagios2″ wiederholt haben, sind wir bereit, den Cluster zu bilden:
 [![DRBD-MC configure
cluster](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%202%20-%20Simon%20Meggle-Dateien/configcluster.jpg "configcluster")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/configcluster.jpg)
 Im anschließend gestarteten *“Cluster Wizard”* benennen Sie die eben
erzeugten Hosts zu Clustermembern:

[![](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%202%20-%20Simon%20Meggle-Dateien/nodeselect.jpg "nodeselect")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/nodeselect.jpg)
 Im Dialog “Corosync/OpenAIS Config File” klicken wir getrost auf
“Next/Keep Old Config” – wir haben bereits alles notwendige in der
corosync.conf manuell konfiguriert. Im abschließenden Dialog “Cluster
Initialization” lässt sich nun Corosync starten, sodass der Asistent am
Ende folgendes spricht:

[![](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%202%20-%20Simon%20Meggle-Dateien/greenshot_2011-05-12_23-05-22.png "allesinstalliert")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/greenshot_2011-05-12_23-05-22.png)
 Beenden Sie den Assistenten. Nun können Sie überprüfen, ob die beiden
Rings, über sich die Nodes überwachen, funktionieren. Die Ring-id muss
der IP-Adresse des Interfaces entsprechen:

{% highlight bash %}

root@nagios1:\~# corosync-cfgtool -s
  Printing ring status.
  Local node ID 167837962
  RING ID 0
  id = 10.1.1.10
  status = ring 0 active with no faults
  RING ID 1
  id = 10.1.2.10
  status = ring 1 active with no faults

{% endhighlight %}

Der Gesamtstatus des Clusters kann ebenfalls noch geprüft werden (achten
Sie auf die letzte Zeile – stehen dort beide Nodes auf “online”?):

{% highlight bash %}

root@nagios1:\~# crm_mon [enter]
  ============
  Last updated: Thu May 5 18:13:03 2011
  Stack: openais
  Current DC: nagios1 - partition with quorum
  Version: 1.0.8-042548a451fce8400660f6031f4da6f0223dd5dd
  2 Nodes configured, 2 expected votes
  0 Resources configured.
  ============

  Online: [ nagios1 nagios2 ]

{% endhighlight %}

Der Vollständigkeit halber werfen wir noch einen Blick in die DRBD-MC –
sie sollte nun die beiden noch jungfräulichen Nodes im Status “online”
anzeigen:

[![](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%202%20-%20Simon%20Meggle-Dateien/greenshot_2011-05-12_23-09-28.png "DRBD-MC Nodes online")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/greenshot_2011-05-12_23-09-28.png)

In [Teil
3](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-3/ "Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 3")
werden wir nun das DRBD-Device einrichten, sowie mit der Definition von
Cluster-Ressourcen beginnen.

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
