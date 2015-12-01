---
layout: post
title:  "Nagios/OMD-Cluster mit Pacemaker/DRBD Teil 5"
date:   2012-01-30 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-5/
---


### Teil 5 – Constraints


Constraints sind das Regelwerk, welches bestimmt, auf welchen Nodes was
zu laufen hat und warum. Es gibt drei Arten von Constraints:

-   *locations*: Wo soll eine Ressource laufen?
-   *colocations*: Welche Ressource soll immer zusammen mit einer
    anderen laufen?
-   *order*: In welcher Reihenfolge sollen Ressourcen gestartet werden?

#### Location


Ganz vorn in der Kette der zu startenden Ressourcen steht eindeutig das
DRBD-Device. Ohne dieses kein Mount, ohne diesen kein Apache, der
starten kann, ohne diesen wiederum kein OMD, und die IP-Adresse ist dann
auch schon egal…
 Wir haben ja bereits die [Ping-Ressource
definiert](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-3),
welche dem Cluster mittles Score seine Netzwerkkonnektivität mitteilen
kann: Also lassen wir doch ein location-Contraint anhand des Scores
entscheiden, auf welchem Node das DRBD „promoted“ werden soll:

{% highlight bash %}

crm(live)configure# location loc_drbdmaster_ping ms_drbd_omd [enter]
rule $id="loc_drbdmaster_ping-rule" $role="Master" pingd: defined pingd [enter]

{% endhighlight %}

Überstetzt bedeutet dieses Constraint so viel wie:

-   erstelle für den Status „Master“ der Multistate-Ressource
    ms_drbd_omd ein location constraint
-   Die interne id soll loc_drbdmaster_ping-rule lauten (opt.)
-   Wenn die interne Variable pingd gültig ist (defined pingd), dann
    soll sie den Score dieses Constraints bestimmen (pingd:)

Nach einem commit sehen wir aber erst mal gar nichts. **Warum**?
 Die Ping-Scores sind aktuell gleich (3000). Es gibt für Pacemaker
keinen Grund, die Ressource zu schwenken. Um genau diesen Schwenk zu
testen, öffnen wir ein neues Konsolenfenster und lassen uns mit
`crm_mon -f` den Cluster-Status, sowie die Scores der pingd-Variablen
dauerhaft anzeigen.

 Wichtig: Sollte die Ressource *pri_fs_omd* gestartet sein, ist auf dem
DRBD noch das Filesystem gemountet. Damit der DRBD-Master testweise auf
den anderen Node ziehen kann, muss das Filesystem natürlich erst
ungemounted, sprich, die entspr. Ressource gestoppt werden:

{% highlight bash %}

crm(live)resource# status pri_fs_omd [enter]
resource pri_fs_omd is running on: nagios1
crm(live)resource# stop pri_fs_omd [enter]

{% endhighlight %}

Aktueller Status “vorher” ist nun: Ping-Score auf beiden Nodes 3000,
DRBD-Master auf node1.

[![](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%205%20-%20Simon%20Meggle-Dateien/vorher.png "vorher")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/vorher.png)

Auf dem DRBD-Primary-Node verbieten wir nun per iptables alle Pings:

{% highlight bash %}

root@nagios1:~# iptables -A OUTPUT -p icmp -j DROP

{% endhighlight %}

Nach kurzer Zeit sollte der Ping-Score im Output von crm_mon so
aussehen:

{% highlight bash %}

Migration summary:
* Node nagios1: pingd=0
* Node nagios2: pingd=3000

{% endhighlight %}

Der Ping-Score auf Node 1 ist nun kleiner als auf Node 2.
Location-Regeln existieren immer pro Ressource pro Node. Das bedeutet:
Die location-Regel für den DRBD-Master auf Node 2 hat sehr viel mehr
Gewicht als die gleiche Regel auf Node 1. Deshalb zieht der Master auf
node2 um:

[![](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%205%20-%20Simon%20Meggle-Dateien/nachher.png "nachher")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/nachher.png)
 Nun erlauben wir nagios1 wieder, zu pingen und flushen (leeren) die
iptables:

{% highlight bash %}

root@nagios1:~# iptables -F

{% endhighlight %}

Der Ping-Score von Nagios1 „erholt“ sich wieder auf 3000. Dass die
DRBD-Master-Rolle nicht wieder zurückschwenkt, liegt an der in [Teil
3](http://blog.simon-meggle.de/tutorials/nagiosomd-cluster-mit-pacemakerdrbd-teil-3/ "Nagios/OMD-Cluster mit Pacemaker/DRBD – Teil 3")
definierten `default-resource-stickiness` größer Null (1). Eine resource
stickiness von > 0 bewirkt, dass die Ressource “lieber” dort bleibt, wo
sie gerade läuft; ist die stickiness kleiner 0, hat die Ressource den
Drang, den Node zu verlassen; eine stickiness von “0″ hat keine
Auswirkung.

Abschließend starten wir die Ressource *pri_fs_omd* auf node 1 wieder –
dass der Mount evt. fehlschlägt, weil er jetzt auf dem Node passiert,
der nicht (mehr) DRBD-Master ist, spielt keine Rolle. Wichtig ist im
Moment nur, dass die Ressource nicht gestoppt ist – Pacemaker würde
sonst auf keinen Fall versuchen, sie zu starten – und das würde ggf. die
ganze Gruppe vom Start abhalten, die nun im Anschluss definiert wird.

{% highlight bash %}

crm(live)resource# status pri_fs_omd [enter]
resource pri_fs_omd is NOT running
crm(live)resource# start pri_fs_omd [enter]

{% endhighlight %}

#### Colocation/Order 1: group_omd folgt DRBD


Der nächste große Schritt ist nun, alle anderen Ressourcen dazu zu
bringen, dem DRBD-Master zu folgen. Wir fassen hierzu den
Filesystem-Mount, den Webserver und die Service-IP in einer Gruppe
zusammen (Achtung: die Reihenfolge, in der die Elemente einer Resource
Group genannt werden, bestimmt zugleich deren Startreihenfolge!)

{% highlight bash %}

crm(live)configure# group group_omd pri_fs_omd pri_apache pri_nagiosIP[enter]
commit [enter]

{% endhighlight %}

Jetzt ist ein guter Zeitpunkt, die DRBD-MC neu zu starten, denn die
derzeit aktuelle Version hat einen Bug: nach dem commit bleiben die
Ressourcen, die in einer Gruppe zusammengefasst werden, als Zombies
stehen). Folgende Gruppe sollte nun angezeigt werden:

[![](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%205%20-%20Simon%20Meggle-Dateien/group_omd.png "group_omd")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/group_omd.png)
 Mittels Colocation weisen wir nun den Cluster an, "group_omd" immer dort
mitzustarten, wo der DRBD-Master läuft – und das mit einem Score von
inf, d.h. unbedingt.

 Zu beachten: Ein colocation constraint wird durch zwei Ressourcen, plus
optional ihre Rollen (z.b. Master) definiert. Die Reihenfolge der
Nennung bestimmt, welche Ressource welcher folgt: “res_a res_b“
bedeutet: „res_a folgt res_b“!

{% highlight bash %}

crm(live)configure# colocation col_omd_follows_drbd inf: group_omd ms_drbd_omd:Master [enter]
commit [enter]

{% endhighlight %}

[![](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%205%20-%20Simon%20Meggle-Dateien/omdfollowsdrbd.png "omdfollowsdrbd")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/omdfollowsdrbd.png)

Wir müssen Pacemaker jetzt mit einem "order" constraint mitteilen, dass
zwischen dem Start der group_omd und dem Promoten des DRBD-Masters eine
Reihenfolge einzuhalten ist.

 *Merke:* Die colocation bestimmt, dass "group_omd" und DRBD-Master
zusammen laufen sollen. Die order legt fest, in welcher Reihnefolge
sie gestartet werden!

{% highlight bash %}

crm(live)configure# order ord_drbd_before_omd inf:ms_drbd_omd:promote group_omd:start [enter]
commit [enter]

{% endhighlight %}

#### Colocation/Order 2: OMD-Site folgt DRBD


Klar, dass unsere OMD-Site nur auf dem Host laufen darf, auf dem das
DRBD promoted ist. Legen Sie also eine colocation an, die unsere
Test-Site an den DRBD-Master bindet. Analog zum vorherigen Schritt ist
auch hier eine Reihenfolge wichtig: die OMD-Site kann erst gestartet
werden, nachdem die Dienste der group_omd aktiv sind. Deshalb schicken
wir gleich noch ein order constraint hinterher:

{% highlight bash %}

crm(live)configure# colocation col_omd_siteA_follows_drbd inf:pri_omd_siteA ms_drbd_omd:Master [enter]
order ord_omd_before_siteA inf: group_omd:start pri_omd_siteA:start [enter]
commit [enter]

{% endhighlight %}

Lassen Sie uns das Ergebnis in der GUI bewundern:

[![](Nagios_OMD-Cluster%20mit%20Pacemaker_DRBD%20-%20Teil%205%20-%20Simon%20Meggle-Dateien/sitaincluded.png "sitaincluded")](http://blog.simon-meggle.de/wp-content/uploads/2011/05/sitaincluded.png)

#### Stunde der Wahrheit: der Test


Öffnen Sie im Browser die URL
[http://nagios/siteA](http://nagios/siteA),
um siteA über die Service-IP des Clusters zu öffnen. Testen Sie nun
bitte selbst das Verhalten des Clusters, indem Sie dem aktiven Node per
iptables einen schlechten Ping-Score geben und verfolgen Sie das schöne
Gezappel in der GUI.

Im nächsten und letzten Teil gehe ich auf die Besonderheiten ein, die
beim Erstellen weiterer OMD-Sites wichtig sind.


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
