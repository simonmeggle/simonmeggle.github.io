---
layout: post
title:  "Score-Berechnung im Pacemaker-Cluster (Colocation Constraints)"
date:   2011-07-02 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/score-berechnung-im-pacemaker-cluster-teil-1/
excerpt: Die Schrauben und Rädchen in Pacemaker
---

Viel ist nicht mehr übrig geblieben von Heartbeat-1, wo ein "Node 2
sieht Node 1 nicht mehr" einer der wenigen Anlässe für den Cluster war,
die Ressourcen umzuziehen. Bei Pacemaker sorgt für die richtige
Verteilung von Ressourcen ein ausgeklügeltes Scoring-System, welches der
folgende Artikel erklären soll. Zum Testen verwenden wir ausschließlich
die Ressource *ocf:heartbeat:Dummy*, um die Beispiele möglichst
generisch zu halten und um uns nicht mit den Eigenheiten von "echten"
Agents herumschlagen zu müssen.

### Vorbereitungen

Wir starten erneut "from scratch", d.h. Sie können (bzw. sollten) dieses
Tutorial mit einem leeren 2-Node-Cluster beginnen:

{% highlight bash %}

crm(live)configure# show [enter]
node node1
node node2
property $id="cib-bootstrap-options"
dc-version="1.0.8-042548a451fce8400660f6031f4da6f0223dd5dd"
cluster-infrastructure="openais"
expected-quorum-votes="2"
stonith-enabled="false"
no-quorum-policy="ignore"

{% endhighlight %}

#### showscores.sh


Dominik Klein hat ein nützliches Shell-Skript geschrieben, welches die
Punkte-Stände aller Ressourcen übersichtlich in einer Tabelle ausgibt.
Da ich selbst einige Zeit damit verbracht habe, eine funktionierende
Version zu finden, habe ich das Script in den
[Download-Bereich](/assets/scoreberechnung-pacemaker/showscores.sh)
aufgenommen (siehe auch [Linux HA Mailing
List](http://www.mail-archive.com/linux-ha@lists.linux-ha.org/msg07258.html)).
 Laden Sie das Script per wget auf mindestens einen Cluster-Node und machen Sie es mit `chmod +x` ausführbar. Ein Testlauf im leeren Cluster sollte folgendes zutage fördern:

{% highlight bash %}

root@node2:~# ./showscores.sh
Resource Score Node Stickiness #Fail Migration-Threshold

{% endhighlight %}

Lassen Sie diese Konsole offen; Sie werden showscores noch öfter
aufrufen.

crm_mon
--------

Öffnen Sie eine weitere Konsole und rufen Sie folgendes Kommando auf:

{% highlight bash %}

root@node2:~# watch -n 1 crm_mon -1f [enter]
============
Last updated: Wed Jun 29 16:14:29 2011
Stack: openais
Current DC: node1 - partition with quorum
Version: 1.0.8-042548a451fce8400660f6031f4da6f0223dd5dd
2 Nodes configured, 2 expected votes
0 Resources configured.
============
Online: [ node1 node2 ]
Migration summary:
* Node node2:
* Node node1:

{% endhighlight %}

### Scores

Scores (zu deutsch: "Punktestände") regeln, auf welchem Node welche
Ressource zu laufen hat. Dabei wird pro Ressource genau ein Score pro
Node definiert, der sich jeweils von -INF(inity) über "0"
bis +INF(inity) erstreckt (INF ist ein Platzhalter für 1.000.000).
 Stellen Sie sich eine große "Score-Tabelle" vor, in deren Spalten die
Nodes, und deren Zeilen die Ressourcen stehen. Jede Zelle beinhaltet
einen "RessourceX auf NodeY"-Score und kann durch Subtraktion und
Addition verändert werden. Scores stehen für Beziehung von Ressourcen zu
den vorhandenen Nodes aus: je höher, desto besser. Ein (noch sinnfreies)
Beispiel:

{% highlight bash %}
  -------------- -------------- -------------- -------------- --------------
                 node1          node2          node3          node4
  resource_x     50             0              -1.000000      20
  resource_y     100            0              -1.000000      20
  resource_z     0              1.000000       0              0
  -------------- -------------- -------------- -------------- --------------
{% endhighlight %}

Der CRM vergleicht nun ständig die Scores innerhalb einer Zeile jeder
Ressource, um den jeweils besten Node für sie zu bestimmen. Der Node mit
dem höchsten Score gewinnt; bei Punktegleichstand darf der Cluster
entscheiden, wo er die Ressource startet.
 Wie bereits erwähnt, führen Rechenoperationen (+/-) auf den Scores zu
Verschiebungen im Punktegleichgewicht, die die Entscheidungsgrundlage
des Clusters beeinflusst.
 Wie und warum werden Scores nun verändert?

#### Dummy-Ressource

Beginnen wir mit einem Minimalbeispiel und definieren eine
Dummy-Ressource:

{% highlight bash %}

crm(live)configure# primitive dummy1 ocf:heartbeat:Dummy [enter]
crm(live)configure# commit [enter]

{% endhighlight %}

Wie Sie im Output von crm_mon (den Sie mit "watch" im Auge behalten)
sehen können, wurde Dummy1 auf Node1 gestartet. Sehen wir uns den Output
von showscores an, um den Grund für diese Entscheidung zu finden:

{% highlight bash %}

root@node2:~# ./showscores.sh [enter]
Resource        Score     Node    Stickiness #Fail    Migration-Threshold
dummy1          0         node2   0          0
dummy1          0         node1   0          0


{% endhighlight %}

Da wir eine Ressource und zwei Nodes haben, enthält die Scoretabelle den
Score "dummy1 auf Node1" und "dummy1 auf Node2", was ich im folgenden
durch "dummy1.Node1/dummy1.Node2" abkürzen werde. Beide Scores sind "0",
in diesem Fall durfte der CRM würfeln und entschied sich für den Start
auf Node1.

#### Migration 1

Zwingen wir nun Dummy1 zur Migration auf Node2:

{% highlight bash %}

crm(live)resource# migrate dummy1 node2 [enter]

{% endhighlight %}

Im Output von crm_mon sehen Sie, dass Dummy1 nun auf Node2 läuft – weit
interessanter ist aber der Output von showscores, den wir nun
untersuchen:

{% highlight bash %}

root@node2:~# ./showscores.sh [enter]
Resource        Score     Node    Stickiness #Fail    Migration-Threshold
dummy1          0         node1   0
dummy1          1000000   node2   0

{% endhighlight %}

Die "migrate"-Anweisung beaufschlagte den Score "dummy1.Node2" mit dem
größtmöglichen Wert (INF), was so viel heißt wie *Dummy1 unbedingt auf
Node2*. Der Punktegleichstand "dummy1.node1:dummy1node2 = 0:0" änderte
sich somit zu "0:1000000" – für den CRM also 1 Million mal mehr Gründe,
Dummy1 auf Node2 laufen zu lassen, als auf Node1.

Die Angabe des Nodes, auf den Migriert werden soll, ist übrigens
optional. Wir werden sehen, wie sich das im Score auswirkt.

#### Migration 2

Heben Sie die Migration zunächst auf und migrieren Sie Dummy1 erneut,
diesmal ohne Angabe des Nodes:

{% highlight bash %}

crm(live)resource# unmigrate dummy1 [enter]
crm(live)resource# migrate dummy1 [enter]
WARNING: Creating rsc_location constraint 'cli-standby-dummy1' with a
score of -INFINITY for resource dummy1 on node1.
This will prevent dummy1 from running on node1 until the constraint is
removed using the 'crm_resource -U' command or manually with cibadmin
This will be the case even if node1 is the last node in the cluster
This message can be disabled with -Q

{% endhighlight %}

Was ist passiert? Dummy1 schwenkte wieder auf Node 2, die Scores wurden
aber auf andere Weise beeinflusst:

{% highlight bash %}

root@node2:~# ./showscores.sh
Resource        Score     Node    Stickiness #Fail    Migration-Threshold
dummy1          0         node2   0
dummy1          -1000000  node1   0

{% endhighlight %}

Diesmal wurde nicht Node2 mit INF bepunktet, sondern Node1 mit -INF! Ein
solcher Score steht für *Dummy1 keinesfalls auf Node1!*.
 Heben wir nun die Migration wieder auf – diesmal auf anderem Wege.
`migrate` und `unmigrate` sind in der crm-Shell nur Abkürzungen, um
location-Constraints zu erzeugen/löschen:

{% highlight bash %}

crm(live)resource# up [enter]
crm(live)# configure [enter]
crm(live)configure# show [enter]
node node1
node node2
primitive dummy1 ocf:heartbeat:Dummy
location cli-standby-dummy1 dummy1 \\
rule $id="cli-standby-rule-dummy1" -inf: #uname eq node1
...
...

{% endhighlight %}

Unser zweiter "migrate"-Befehl erzeugte einen location-Constraint, der
wie folgt zu übersetzen wäre: *Definiere einen Location Constraint
namens ‘cli-standby-dummy1′ mit dem Wert -INF für die Ressource
‘dummy1′, sie soll aber nur für den Node gelten, dessen Hostname = node1
lautet.*

Löschen des location Constraints bewirkt also genau das gleiche wie
der Befehl `unmigrate`:

{% highlight bash %}

crm(live)configure# delete cli-standby-dummy1
crm(live)configure# commit

{% endhighlight %}

### Stickiness

Wer genau aufgepasst hat, stellte sich vielleicht die Frage, warum
"Dummy1" nach dem Löschen des location-Constraints wieder auf Node 1
schwenkte – immerhin zeigt die Scoretabelle einen Score von 0:0. Hätte
der Cluster nicht "würfeln" sollen bzw. hätte Dummy1 nicht auch auf
Node2 gestartet werden können?

Nein. Sofern nicht anders konfiguriert, versucht Pacemaker nach einem
Failover stets den Originalzustand wiederherzustellen (unter heartbeat
gab es hierfür die Option auto_failback). Sofern es keinen Grund
hierfür gibt, ist dieser Schwenk zurück i.d.R. sinnlos und kostet nur
Zeit. Es muss also eine Möglichkeit geben, die den Scores noch eine
weitere, dynamische Gewichtung verleiht – die Stickiness.

"Stickiness" (dt. "Klebrigkeit") wird pro Ressource definiert und
beschreibt ihren "Willen", auf dem Node zu verweilen, auf dem sie
aktuell läuft. Ihr Wertebereich erstreckt sich ebenfalls von -INF(inity)
über "0" bis +INF(inity).

Um also zu vermeiden, dass Dummy1 nach einem Recovery von Node1 wieder
zurückschwenkt (also bei Score-Gleichstand), definieren wir eine
default-stickiness von 1:

{% highlight bash %}

crm(live)configure# property default-resource-stickiness="1" [enter]
crm(live)configure# commit [enter]

{% endhighlight %}

Beachten Sie, wie sich der Output von Scores verändert hat:

{% highlight bash %}

Resource        Score     Node    Stickiness #Fail    Migration-Threshold
dummy1          0         node2   1          0                        
dummy1          1         node1   1          0

{% endhighlight %}

Dass die eben definierte default-Stickiness für alle Ressourcen auf
allen Nodes gilt, sehen Sie an der Spalte "Stickiness". Nun beginnt sie,
die Cluster-Mathematik: da Dummy1 auf Node1 läuft, wird dessen
ursprünglicher Score (0) noch um dem Wert der Stickiness (1) erhöht. Das
gibt Dummy1.Node1 ein um die Stickiness erhöhtes Gewicht.

Testen wir die Stickiness: migrieren Sie Dummy 1 von Node1 weg:

{% highlight bash %}

crm(live)resource# migrate dummy1 [enter]

{% endhighlight %}

Beachten Sie, wie der Score von Dummy1.Node2 von 0 auf 1 (=um die
Stickiness) erhöht wird. Dummy1.Node1 wird mit -INF bestraft:

{% highlight bash %}

Resource        Score     Node    Stickiness #Fail    Migration-Threshold
dummy1          -1000000  node1   0          0
dummy1          1         node2   1          0

{% endhighlight %}

Jetzt kommt es drauf an: entfernen Sie den location constraint (entweder
über `crm configure delete cli-standby-dummy1` oder `crm resource
unmigrate dummy1`) – die Ressource sollte nun auf Node2 verweilen. Ein
Blick auf die Scores verrät, warum:

{% highlight bash %}

Resource        Score     Node    Stickiness #Fail    Migration-Threshold
dummy1          0         node1   1          0                        
dummy1          1         node2   1          0

{% endhighlight %}

Nach Entfernen des constraints behält Node2 die Macht über Dummy1, weil
dessen Stickiness zum Score gezählt wurde.

### Scores und Constraints

Mit Constraints lassen sich Bedingungen festlegen, die die Platzierung
der Ressourcen steuern. Umgesetzt werden constraints ebenfalls über die
Punkteverteilung, dessen Regelwerk wir nun kennenlernen werden. Erzeugen
Sie hierzu eine zweite Dummy-Ressource:

{% highlight bash %}

crm(live)configure# primitive dummy1 ocf:heartbeat:Dummy [enter]
crm(live)configure# commit [enter]

{% endhighlight %}

Auch wenn Dummy2 wahrscheinlich auch bei Ihnen auf dem noch freien Node
(hier: Node2) gestartet wurde, möchten wir dies fest definieren – wir
kommen zu location constraints:

### Location-Constraints

Wir möchten nun per location constraint erreichen, dass Dummy2 immer auf
Node2 gestartet wird. Hierzu schreiben Sie folgenden Befehl in die
crm-Shell:

{% highlight bash %}

crm(live)configure# location loc_dummy2_node2 dummy2 10000: node2
crm(live)configure# commit

{% endhighlight %}

(Zum besseren Verständnis für das Zustandekommen der Scores habe ich
anstatt INF den Wert 10000 verwendet, denn z.B. "INF plus 5" ergibt INF
– nicht gerade günstig für Erklärungen….)
 Showscores.sh zeigt uns nun deutlich, wie Pacemaker den
Location-Constraint in Scores ausgedrückt hat:

{% highlight bash %}

Resource        Score     Node    Stickiness #Fail    Migration-Threshold
dummy1          0         node2 1          0                        
dummy1          1         node1 1          0                        
dummy2          0         node1 1          0                        
dummy2          10001     node2 1          0

{% endhighlight %}

Ohne Location constraint hätte Dummy2/Node 2 exakt den gleichen Score
erhalten wie Dummy1/Node1, nämlich "1" (Sie erinnern sich, die
Stickiness…). Dummy2 erhielt auf Node2 aber durch den Location
Constraint zusätzlich 10.000 mal mehr Gewicht. Für den CRM wird es also
erst mindestens 10.002 Gründe geben müssen, Dummy2 auf einem anderen
Node zu starten!

### Preisfrage…

1) Was wird wohl passieren, wenn Sie jetzt auch noch folgenden Befehl
eingeben?
2) Welchen Score wird dummy2/Node2 danach haben?

{% highlight bash %}

crm(live)configure# location loc_dummy2_backtonode1 -10001: node2
[commit]

{% endhighlight %}

*Antwort zu 1*: Nichts wird passieren, weil noch ein "commit" fehlt. Ok, das war gemein. Nach dem Commit aber wird Dummy2 zurück auf Node 1 schwenken.

*Antwort zu 2*: Wenn Sie jetzt auf "0" getippt haben, war das zwar schon
gut, stimmt aber nicht ganz. Erinnern Sie sich: der erste Location
Constraint punktete mit 10.000, der zweite zieht davon jetzt wieder
10.001 ab:

{% highlight bash %}

location loc_dummy2_node2 dummy2 10000: node2
location loc_dummy2_backtonode1 dummy2 -10001: node2

{% endhighlight %}

Somit ergibt sich für Dummy2.Node2 ein Score von "-1" – demgegenüber
steht "0" auf Node 1, was die Ressource dorthin zieht. Die Stickiness
wird dann "on top" dort aufaddiert, wo die Ressource läuft – was zu
folgenden Scores führt:

{% highlight bash %}

Resource        Score     Node    Stickiness #Fail    Migration-Threshold
dummy1          0         node2 1          0                        
dummy1          1         node1 1          0                        
dummy2          1         node1 1          0                        
dummy2          -1        node2 1          0

{% endhighlight %}

Löschen Sie die beiden location constraints, bevor Sie zum nächsten
Abschnitt übergehen.

#### Colocation-Constraints

(oder: zu Dir oder zu mir?)

Colocation-Constraints bestimmen, welche Ressourcen zusammen (oder im
Gegenteil: auf keinen Fall zusammen) laufen sollen und werden mit Scores
(-INF bis +INF) versehen. Positive colocation-scores stehen für
Zuneigung, negative Scores hingegen lassen darauf schließen, dass sich
die Ressourcen aus dem Weg gehen. Die Reihenfolge, in der die Ressourcen
genannt werden, bestimmt die Richtung der Zu/Abneigung. Die
Score-Berechnung wird jetzt einiges interessanter! Bauen Sie folgendes
Testszenario:

#### Testszenario 1: Colocation per INF

{% highlight bash %}

primitive A ocf:heartbeat:Dummy
primitive B ocf:heartbeat:Dummy
location locA A 100: node1
location locAa A 3: node2
location locB B 9: node1
location locBb B 25: node2
colocation col inf: B A

{% endhighlight %}

Committen Sie den Aufbau und lassen Sie die Ausgabe von showscores.sh
geöffnet, während Sie weiterlesen.

{% highlight bash %}

Resource   Score     Node    Stickiness #Fail    Migration-Threshold
A          109       node1   0
A          28        node2   0
B          -1000000  node2   0
B          9         node1   0

{% endhighlight %}

Wie kommen diese Werte zustande?

Der CRM steht zu Beginn vor zwei Aufgaben, nämlich den jeweils besten
Node für A und B herauszufinden. A und B müssen per colocation
constraint zusammen laufen (INF, "B folgt A"), weshalb zunächst für A
der beste Node bestimmt werden muss – wie B seinen Node findet, sehen
wir gleich.

Für die Wahl eines passenden Nodes für A ist nicht nur der Score A.nodeX
entscheidend, sondern außerdem die Scores der per colocation an ihn
gebundenen Ressourcen (hier: B). Diese werden zu seinem Score addiert
(ignorieren Sie bitte, dass die jeweils zweiten Operanden noch mit eins
multipliziert werden. Im nächsten Abschnitt erfahren Sie, warum):

{% highlight bash %}
A.node1.score = A.node1.score + 1*B.node1.score = 100 + 1*9 = 109
A.node2.score = A.node2.score + 1*B.node2.score = 3 + 1*25 = 28
{% endhighlight %}

Je mehr Punkte die Ressource A also mitsamt ihrer per colocation
verbundenen Ressourcen auf einem Node sammeln kann, desto größer ist die
Wahrscheinlichkeit, dass A auch auf diesem Node gestartet wird. Die Wahl
des Nodes für A ist somit gefallen: Node 1 führt mit 109 Punkten. Sie
sehen diese Werte auch im Output von showscores.sh.

Nennen wir Node 1 den "Matchnode"; er hat das Rennen für Ressource A
gewonnen. Klar, dass B nun auch auf diesem zu laufen hat – aber wie
denkt der Cluster?

Hier greift eine etwas starre Regel:

{% highlight bash %}
B.Matchnode.score = B.Matchnode.score
B.LooseNodes.score = -INF = -1.000000
{% endhighlight %}

Sie ahnen, was mit der zweiten Zeile erreicht wird: ein Score von -INF
verbietet der Ressource B den Start auf allen Nodes außer dem Matchnode
– dort bleibt ihr Score unverändert (9).

#### Testszenario 2: Colocation per -INF

Wie sieht die Punkteverteilung nun bei einer Colocation aus, die
mit -INF invertiert wurde?

 Invertieren Sie die colocation aus Testszenario 1, in dem Sie in der
CRM-configure-Shell `edit` eingeben. Es startet sich eine temporäre
vi-Session, in der Sie die komplette Cluster-Konfiguration (mit
entsprechender Vorsicht…) händisch editieren können:

{% highlight bash %}

crm(live)configure# edit [enter]
...
colocation col -inf: B
...

{% endhighlight %}

Verlassen Sie den vi per `:wq` und committen Sie die Änderung. Bringen
Sie den Output von showscores.sh in den Vordergrund, um die
Scoreverteilung zu begutachten:

{% highlight bash %}

Resource   Score     Node    Stickiness #Fail    Migration-Threshold
A          -22       node2   0                                   
A          91        node1   0                                   
B          -1000000  node1   0                                   
B          25        node2   0

{% endhighlight %}

Die im vorigen Beispiel verwendete Multiplikation mit 1 war das Ergebnis
des Ausdrucks (col.score/INF). "col.score", also der Score des
colocation constraints, war dort mit INF gewichtet, sodass INF/INF dort
in 1 resultierte.

Für dieses Beispiel ist der constraint mit "-INF" negiert worden,
sodass die Division "-1" ergibt. Der zweite Operand der Aufsummierung
wird diesmal negativ, sodass wir vom Score der Ressource A also den
Score der Ressource B abziehen.

{% highlight bash %}
A.node1.score = A.node1.score + (col.score/INF)*B.node1.score = 100 +
(-INF/INF)*9 = 100 + (-1)*9 = *91*
 A.node2.score = A.node2.score + (col.score/INF)*B.node2.score = 3 +
(-INF/INF)*25 = 3 + (-1)*25 = *-22*
{% endhighlight %}

Für Ressource A ist auch diesmal wieder Node 1 der Matchnode (91
Punkte). Die Scores für Ressource B werden dieses Mal genau andersherum
gesetzt:

{% highlight bash %}
B.Matchnode.score = *-INF = -1.000000*
B.LooseNodeX.score = *B.LooseNodeX.score*
{% endhighlight %}

In diesem Fall setzt Pacemaker den Score B.Matchnode auf -INF, um
vermeiden, dass B zusammen mit A läuft. Da der Score B.Node2 unverändert
(und damit höher als -INF) ist, darf B auf Node 2 starten. Bei einem
Cluster mit "n" Nodes gibt es natürlich (n-1) LooseNodes. Sind die
Scores für B auf diesen Nodes unterschiedlich gesetzt worden, gewinnt
der höchste. Sind alle Scores gleich, entscheidet der CRM nach Anzahl
der Ressourcen – B wird dann dort gestartet, wo noch wenigsten
Ressourcen laufen.

### Scoring-Regel für Colocation Constraints

Wenn wir beim colocation-Beispiel "B folgt A" bleiben, lassen sich
folgende Regeln zur Berechnung der Scores herleiten:

{% highlight bash %}
A.node1.score = A.node1.score + (col.score/INF)*B.node1.score
A.node2.score = A.node2.score + (col.score/INF)*B.node2.score
#col.score > 0:
B.Matchnode.score = B.Matchnode.score
B.LooseNodeX.score = -INF*
#col.score < 0:
B.Matchnode.score = -INF
B.LooseNodeX.score = B.LooseNodeX.score
{% endhighlight %}
