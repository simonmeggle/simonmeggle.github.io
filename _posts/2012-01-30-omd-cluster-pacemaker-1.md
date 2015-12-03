---
layout: post
title:  "Nagios/OMD-Cluster mit Pacemaker/DRBD Teil 1"
date:   2012-01-30 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-1/
excerpt: Bau eines hochverfügbaren Monitoring-Systems
---

Zum Thema
=========

Motivation
----------

[OMD](www.omdistro.org) (Open Monitoring Distribution) macht die Installation eines
kompletten Monitoring-Systems zum Kinderspiel. Das Konzept, die
komplette Nagios-Installation incl. (fast) aller Schikanen in einem
einzigen Verzeichnis unterzubringen, Sites einfach zu klonen oder
testhalber neu zu erstellen, ist so einfach wie genial – selbst der
komplette Nachbau eines Systems nach einem Hardwareausfall auf einem
neuen Server sollte in weniger als 60 Minuten über die Bühne gehen.

Apropos Hardwareausfall. OMD erleichtert zwar die Installation und
Administration des Monitorings, erhöht aber in keinster Weise dessen
Verfügbarkeit; ein toter OMD-Server ist ein toter OMD-Server.
 Da es hierzu noch keine brauchbare Dokumentation gibt, habe ich mich
selbst ans Werk gemacht, OMD im Cluster laufen zu lassen. Wichtig dabei
war mir, die Architektur von OMD dabei nicht zu durchbrechen und nur so
viel zu modifizieren, dass die OMD-Installation in sich konsistent (und
somit auch updatefähig) bleibt.

Inhalt
------

In diesem mehrteiligen Tutorial lernen Sie, mit DRBD, Pacemaker, OMD und
LVM ein hochverfügbares Monitoring-System aufzubauen. Wir starten
tatsächlich “bei Null” mit der Installation der Server und enden mit
einem hochverfügbaren Monitoringsystem – ich hoffe, ich kann damit all
denen helfen, die die Vorteile von OMD auf einem ausfallsicheren System
nutzen wollen. Ich denke da z.b. an *Dienstleister*, die “Monitoring as
a Service” anbieten und dem Kunden Zugriff auf “seine” Nagios-Umgebung
bieten möchten. Mit einer OMD-Site ist ein solcher Service zwar schnell
aufgesetzt, jedoch hängt dieser dann an einem seidenen Faden: der
darunterliegenden Hardwareschicht.

Wir bauen uns also einen Cluster, in dem folgende Technologien zum
Einsatz kommen werden:

-   **[OMD](http://omdistro.org/ "OMD")
    – Open Monitoring Distribution**: Nagios aufzusetzen, war nie
    leichter. Wer die Installations/Konfigurations-Orgie kennt, die ein
    vollständig ausgestatter Nagios-Server mit Datenbankanbindung,
    RRD-Graphen, Visualisierung, Wiki etc. erfordert, wird die Vorteile
    von OMD schnell zu schätzen lernen. Ein Team von Nagios-Freaks hat
    sich zusammengesetzt und ein Paket geschnürt, mit dem sich der
    Installationsaufwand drastisch minimiert. (Natürlich auch empfohlen
    in nicht geclusterten Umgebungen)
     Weitere Infos zu OMD finden sich auf der Projektseite.
-   **[DRBD](http://drbd.org/)
    – Distributed Replicated Block Device**: “RAID1 übers Netzwerk”
-   **LVM – Logical Volume Manager**: Abstraktionsebene unter
    Unix/Linux, welche die Erstellung von dynamisch veränderbaren
    Partitionen (Logical Volumes) erlaubt.
-   [**Pacemaker/Corosync**](http://clusterlabs.org/): Früher Teil des Linux-HA-Projektes, ist Pacemaker seit 2008 der
    offizielle Nachfolger des bekannten *Heartbeats.* Die Kommunikation
    der Nodes untereinander wird durch Corosync geregelt.


Am Ende werden Sie einen Cluster betreiben und administrieren können,
welcher

-   aus zwei Nodes besteht (Active/Passive)
-   beim Ausfall des aktiven Nodes
    -   das DRBD-Device promoted
    -   das Filesystem darauf mountet, in welchem die variablen
        OMD-Daten liegen
    -   die virtuelle Service-IP übernimmt
    -   die OMD-Sites startet

Vorkenntnisse zu DRBD, LVM und Pacemaker sind von Vorteil.
 Sofern nicht anders angegeben, beziehen sich Terminalangaben auf beide
Nodes.

### Teil 1 – Vorbereitung der Server


Es empfiehlt sich, das Tutorial mit virtuellen Test-Maschinen
abzuarbeiten, um “Zwischenerfolge” per Snapshot sichern zu können (an
geeigneter Stelle werde ich darauf hinweisen). Die Wahl der
Virtualisierungssoftware überlasse ich Ihnen – beste Erfahrungen habe
ich mit Virtualbox gemacht (unter Ubuntu Desktop 10.04). Wer bereits
sattelfest ist und möglichst schnell ein Produktivsystem haben will,
kann sich natürlich sofort an echtes Blech wagen.

#### Installation von Ubuntu 10.04


Erstellen Sie zwei virtuelle Maschinen mit

-   einer (dynamisch wachsenden) System-Platte, z.b. 10GB (sda)
-   einer (dynamisch wachsenden) Daten-Platte, z.b. 5GB
-   ca. 500 MB RAM
-   drei Netzwerkkarten:
    -   eth0: mit Zugang zum LAN
    -   eth1 + eth2: isoliertes Netzwerk, d.h. die Netzwerkkarten der
        beiden Nodes sind jeweils direkt über Kabel verbunden (eth1 mit
        eth1, eth2 mit eth2)

und installieren Sie darauf Ubuntu Server 10.04 LTS. Bei der
abschließenden Software-Auswahl installieren Sie lediglich gleich den
openssh-Server.

#### Konfiguration


Loggen Sie sich auf der Konsole *beider* Maschinen mit dem in der
Installation vergebenen Usernamen ein und und erlauben Sie sogleich den
direkten Root-Login (nicht empfohlen für Produktivsysteme!):

{% highlight bash %}

user@nagios1:~$ sudo su -
[sudo] password for user:
root@nagios1:~# passwd

{% endhighlight %}

Geben Sie beiden Maschinen einen Namen:

{% highlight bash %}

root@nagios1:~# vim /etc/hostname
nagios1 (bzw. nagios2)

{% endhighlight %}

Legen Sie in *beiden* Maschinen folgende Hostnamen ab; tragen Sie diese
Namen ebenfalls in die hosts–Datei Ihres Desktops bzw. in Ihren
DNS-Server ein:

{% highlight bash %}

root@nagios1:~# vim /etc/hosts
192.168.55.30 nagios
192.168.55.10 nagios1
192.168.55.20 nagios2

{% endhighlight %}

Vergeben Sie auf *beiden* Nodes IP-Adressen…

{% highlight bash %}

root@nagios1:~# vim /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
address 192.168.55.(10|20)
netmask 255.255.255.0
gateway 192.168.55.1

# Corosync 1
auto eth1
iface eth1 inet static
address 10.1.1.(10|20)
netmask 255.255.255.0

# Corosync 2
auto eth2
iface eth2 inet static
address 10.1.2.(10|20)
netmask 255.255.255.0

{% endhighlight %}

…und starten sie auf *beiden* Servern das Netzwerk:

{% highlight bash %}

root@nagios1:~# invoke-rc.d networking restart

{% endhighlight %}

Sie sollten nun von jeder Maschine einen Ping zur anderen absetzen
können. Verbinden Sie sich nun per SSH auf beide Maschinen.
 Bringen Sie das System auf den neuesten Stand (dauert je nach
Verbindung ca. 10 Minuten):

{% highlight bash %}

root@nagios1:~# sudo apt-get update && sudo apt-get dist-upgrade

{% endhighlight %}

Wenn Sie dieses Tutorial mit virtuellen Maschinen durchführen, ist jetzt
ein guter Zeitpunkt, um die Gasterweiterungen der
Virtualisierungssoftware zu installieren.

#### Installation der benötigten Pakete


Für die Eiligen: Alle für die im folgenden genannten Schritte benötigten
Pakete sind hier zusammengefasst:

{% highlight bash %}

root@nagios1:~# apt-get install tree ntp lvm2 git-core automake autoconf
module-assistant debconf-utils docbook-xml docbook-xsl dpatch flex
xsltproc debhelper corosync pacemaker fuse-utils xinetd libdbi0
libapache2-mod-php5 libapache2-mod-python libapache2-mod-fcgid
libapache2-mod-proxy-html php5-gd php5-sqlite php5-mcrypt graphviz snmp
libgd2-xpm dnsutils fping mysql-server php-pear php5 php5-cli smbclient
unzip libnet-snmp-perl libsnmp-perl rsync dialog libpango1.0-0 curl
patch libreadline5 pyro

{% endhighlight %}

#### NTP

Für so ziemlich alles, was wir auch in Zukunft clustern wollen, ist eine
zuverlässige Zeitsynchronisation der zwischen den beiden Nodes eine gute
Grundlage. Deshalb installieren wir auf *beiden* Nodes den NTP-Daemon…

{% highlight bash %}

root@nagios1:~# apt-get install ntp

{% endhighlight %}

…und konfigurieren ihn:

{% highlight bash %}

root@nagios1:~# vim /etc/ntp.conf
# tragen Sie hier die IP-Adresse eines Zeitservers ein
# minpoll=Intervall, in dem die Zeitquelle abgefragt werden soll;
# maxpoll=maximaler Abstand zwischen zwei Abfragen.
# (Zeiteinheiten a 16 Sekunden!)
server 192.168.1.2 minpoll 4 maxpoll 10
# vermeidet bei zu großer Zeitdifferenz, dass NTP die Synchronisation
verweigert
tinker panic 0

{% endhighlight %}

Anschließend Restart des NTP-Daemons:

{% highlight bash %}

root@nagios1:~# invoke-rc.d ntp restart

{% endhighlight %}

Prüfen, ob die Synchronisation klappt:

{% highlight bash %}

root@nagios1:~# ntpq -p
remote refid st t when poll reach delay offset jitter
==============================================================================
ntpsrv.local 192.168.1.23 2 u 3 16 1 1.579 -185825 0.001

{% endhighlight %}

Der Offset ist mit -185825 natürlich sonstwo. Ein initialer
Sync:

{% highlight bash %}

root@nagios1:~# invoke-rc.d ntp stop && ntpdate 192.168.1.23 &&
invoke-rc.d ntp start

{% endhighlight %}

#### LVM-Einrichtung

Die variablen Daten, auf die beide Nagios-Nodes später zugreifen sollen,
werden auf einer Partition auf der Datenplatte sdb gehalten werden, die
wir mit LVM verwalten lassen. Sollten Sie mit LVM nicht vertraut sein,
kann ich Ihnen die
[LVM-Erklärung](http://blog.zugschlus.de/archives/65-LVM-unter-Linux.html)
von Marc ‘Zugschlus’ Haber nahelegen.

Installieren Sie LVM auf *beiden* Nodes über

{% highlight bash %}

root@nagios1:~# apt-get install lvm2

{% endhighlight %}

Erstellen Sie auf *beiden* Nodes zunächst eine neue primäre Partition für den noch freien
Bereich auf der Festplatte:

{% highlight bash %}

root@nagios1:~# fdisk /dev/sdb
n  > neue Partitoin
p  > primäre Partition
1  > Nummer der primären partition
t  > Typ
8e > LVM
w  > write

{% endhighlight %}

Nun legen wir auf *beiden* Nodes Physical Volume, Volume Group, und das
Logical Volume an (letzteres soll die Volume Group zunächst nur mit 80%
belegen):

{% highlight bash %}

root@nagios1:~# pvcreate /dev/sdb1
  Physical volume "/dev/sdb1" successfully created
  root@nagios1:~# vgcreate vgdata /dev/sdb1
  Volume group "vgdata" successfully created
  root@nagios1:~# lvcreate -l 80%VG -n lvomd vgdata
  Logical volume "lvomd" created

{% endhighlight %}

Das logical Volume lvomd wird mit keinem Dateisystem formatiert und auch
nicht gemountet. Es ist das Raw Device, welches wir über DRBD zum
anderen Node replizieren.

#### DRBD-Installation

In meinen Tests habe ich festgestellt, dass die Installation per
git-clone am einfachsten von der Hand geht. Folgende Pakete sind auf *beiden* Nodes zu
installieren:

{% highlight bash %}

root@nagios1:~# apt-get install git-core automake autoconf module-assistant
debconf-utils docbook-xml docbook-xsl dpatch flex xsltproc debhelper

{% endhighlight %}

Checken Sie die Sourcen von DRBD aus:

{% highlight bash %}

root@nagios1:~# cd /usr/src
root@nagios1:~# git clone git://git.drbd.org/drbd-8.3.git
root@nagios1:~# cd drbd-8.3

{% endhighlight %}

Lassen Sie nun aus den Sourcen Debian-kompatible Pakete bauen…

{% highlight bash %}

root@nagios1:~# dpkg-buildpackage -rfakeroot -b -uc

{% endhighlight %}

…die Sie nun wie gewohnt installieren:

{% highlight bash %}

root@nagios1:~# cd ..
root@nagios1:~# dpkg -i drbd8-*

{% endhighlight %}

Was noch fehlt ist das Kernelmodul für DRBD, installieren Sie dieses
über

{% highlight bash %}

root@nagios1:~# module-assistant auto-install drbd8

{% endhighlight %}

(Es kann sein, dass an dieser Stelle noch Kernelheader installiert
werden.)
 Starten Sie anschließend beide Nodes durch. Dass das Modul im Anschluss
erfolgreich geladen werden konnte, sehen Sie mit

{% highlight bash %}

root@nagios1:~# lsmod | grep drbd
  drbd 284143 0

{% endhighlight %}

#### Pacemaker/Corosync-Installation

Installieren Sie auf *beiden* Nodes die benötigten Pakete:

{% highlight bash %}

root@nagios1:~# apt-get install corosync pacemaker fuse-utils

{% endhighlight %}

Damit Corosync beim Systemstart startet, ist die default-config auf
“yes” zu setzen:

{% highlight bash %}

root@nagios1:~# vim /etc/default/corosync
  START=yes

{% endhighlight %}

#### OMD-Installation

Nun fehlt nur noch die Installation von OMD selbst. Installieren Sie auf *beiden* Nodes alle für OMD benötigten Pakete:

{% highlight bash %}

root@nagios1:~# apt-get install xinetd libdbi0 libapache2-mod-php5 libapache2-mod-python libapache2-mod-fcgid libapache2-mod-proxy-html php5-gd php5-sqlite php5-mcrypt graphviz snmp libgd2-xpm dnsutils fping mysql-server php-pear php5 php5-cli smbclient unzip libnet-snmp-perl libsnmp-perl rsync dialog libpango1.0-0 curl patch libreadline5 pyro

{% endhighlight %}

Während der Installation der Pakete werden Sie nach dem Passwort für die
MySQL-Datenbank gefragt. Notieren Sie dieses. Laden Sie von der OMD-Homepage das OMD-Paket für Ubuntu herunter…

{% highlight bash %}

root@nagios1:~# wget http://omdistro.org/attachments/download/66/omd-0.46_lucid1_i386.deb

{% endhighlight %}

…und installieren Sie es anschließend:

{% highlight bash %}

root@nagios1:~#  dpkg -i omd-0.46_lucid1_i386.deb

{% endhighlight %}

Ein erster Schnell-Test, um die OMD-Installation zu prüfen, sollte vorab
auf beiden Hosts ausgeführt werden (das ist deshalb wichtig, um später
den DRBD/Pacemaker-Cluster als Fehlerquelle ausschließen zu können). Wie
der Output des Installationsscriptes bereits ausgibt, ist zunächst
Apache neu zu starten. OMD hat sich nämlich ins Verzeichnis
/etc/apache/conf.d mit einer Datei namens zzz_omd.conf eingeschlichen.
Anhand dieser Datei (bzw. der include-Direktiven darin) wird dem Apache
mitgeteilt, dass er fortan als Proxy für die dedizierten Apachen der
OMD-Sites dienen soll:

{% highlight bash %}

root@nagios1:~# invoke-rc.d apache2 restart

{% endhighlight %}

Nun erstellen wir auf dem *ersten* Node (nagios1) eine Test-OMD-Site:

{% highlight bash %}

root@nagios1:~# omd create siteA
  Adding /omd/sites/siteA/tmp to /etc/fstab.
  Created new site siteA with version 0.46.
  Restarting Apache...OK
  Creating temporary filesystem...OK
  Successfully created site siteA.

  The site can be started with omd start siteA.
  The default web UI is available at http://nagios1/siteA/
  The admin user for the web applications is omdadmin with password omd.
  Please do a su - siteA for administration of this site.

{% endhighlight %}

Mit diesem Befehl wurde auf dem ersten Node auch ein User “siteA” angelegt;
die Site wird im Kontext dieses Users laufen. Für Linux sind User- und
Gruppennamen Schall und Rauch – sie werden über die Datei /etc/passwd in
UIDs und GIDs übersetzt. Damit nachher auch auf dem zweiten Node mit dem
dortigen User “siteA” auf die gesharten Site-Files zugegriffen werden
kann, müssen wir sicherstellen, dass beim Anlegen der Site auf Node2 UID
und GID mit denen auf Node 1 übereinstimmen.

Lassen Sie sich auf Node 1 also die IDs des erstellten
Site-Users ausgeben:

{% highlight bash %}

root@nagios1:~# id siteA
  uid=114(siteA) gid=512(siteA) Gruppen=512(siteA),103(omd)

{% endhighlight %}

Das Kommando zur Erstellung von siteA auf *Node 2* lautet nun fast gleich;
hinzu kommen lediglich die Parameter -u und -g, mit denen die
User/Gruppen-ID des Site-Users vorbestimmt werden kann:

{% highlight bash %}

root@nagios2:~# omd create siteA -u 114 -g 512

{% endhighlight %}

Die Testsite “siteA” lässt sich auf *beiden* Nodes starten mit:

{% highlight bash %}

root@nagios1:~# omd start siteA

{% endhighlight %}

Nun überzeugen Sie sich davon, dass sich die OMD-WUI
([http://nagios1/siteA](http://nagios1/siteA),
Default-Login mit „omdadmin“/„omd“) aufrufen lässt und funktioniert.

Stoppen Sie die Sites nun wieder auf *beiden* Nodes:

{% highlight bash %}

root@nagios1:~# omd stop siteA

{% endhighlight %}

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
