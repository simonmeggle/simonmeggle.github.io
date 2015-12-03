---
layout: post
title:  "check_smstrade.pl - Guthabenabfrage für Nagios"
date:   2010-08-19 12:58:14 +0100
categories: tutorials
comments: true
permalink: /tutorials/check-smstrade/
excerpt: ein Nagios-Plugin zum Monitoring des Restguthabens bei SMS-Providern
---

![](/assets/check_smstrade/blackberry.png)

Damit Nagios stets SMS versenden kann, sollte auch das Guthaben bei
einem SMS-Provider wie
[SMStrade.de](http://www.smstrade.de/)
überwacht werden. SMStrade liefert den aktuellen Credit per HTTP-Request
aus, sodass ein Check in Perl schnell zusammengeschustert war.
 Der Check wirft auch Performancedaten aus, sodass man die Menge der
versendeten SMS resp. das verbleibende Guthaben auch im Graphen
bewundern kann.

In dieser Kurzbesprechung will ich auf die Verwendung des Perl-Moduls
Nagios::Plugin eingehen, mit dem neue Nagios-Checks in Windeseile gebaut
sind und auch gleich den Nagios-Konventionen entsprechen.

{% highlight bash %}

use Nagios::Plugin;
use LWP::Simple;
use Math::Round qw/nearest/;

{% endhighlight %}

Hiermit werden drei Perl-Module importiert; von Math::Round wird nur die
Funktion `nearest` benötigt. Sie rundet den von SMStrade dreistellig
ausgegebenen Betrag auf einen zweistelligen.

{% highlight bash %}

my $url = "http://gateway.smstrade.de/credits/?key=____________";

{% endhighlight %}

Unter dieser URL wird das Guthaben ausgegeben. Beachten Sie dass der Key
natürlich der zu Ihrem Account gehörende sein muss.

{% highlight bash %}

*Nagios::Plugin::Functions::get_shortname = sub {
        return undef;
};

{% endhighlight %}

Ein kleiner Hack, der verhindert, dass die Plugin-Ausgabe mit dem
shortname des Plugins beginnt.

{% highlight bash %}

my $np = Nagios::Plugin->new(
        shortname => 'check_smscredit',
        usage   => 'Usage: %s [-w|--warning=] [-c|--critical=]',
        blurb   => 'Prüft das Guthaben bei SMSTrade und schlägt Alarm,
wenn dieses unter die zulässigen Grenzwerte fällt, um rechtzeitig neues
Guthaben zu überweisen.',
);

{% endhighlight %}

Per Konstruktor `->new()` wird ein neues Objekt `np` vom Typ
`Nagios::Plugin` erzeugt. `Usage` wird angezeigt, wenn der Pluginaufruf
fehlschlägt bzw. das Plugin mit `–-help` oder `–-usage` aufgerufen wird.
`blurb` ist ein Text, der kurz den Zweck des Plugins beschreiben soll.

{% highlight bash %}

$np-> add_arg(
        spec    => 'warning|w=i',
        help    => 'Warning threshold.',
        default => 10,
);
$np->add_arg(
        spec    => "critical|c=i",
        help    => 'Critical threshold.',
        default => 5,
);

{% endhighlight %}

Warning und Critical Schwellwert. Der Wert zum Hash-key `spec` zeigt an,
dass es sich hierbei um Integerzahlen handelt und diese entweder mit
`warning` oder `w` bzw. `critical` und `c` angegeben werden können.
`help` speichert einen kleinen Hilfetext, der beim Aufruf des Plugins
mit `–help` ausgegeben wird. `default` gibt einen Standardwert vor,
sollte der Parameter nicht angegeben worden sein.

{% highlight bash %}

$np->getopts();
$np->set_thresholds(
        warning => ($np->opts->warning()),
        critical => ($np->opts->critical()),
);

{% endhighlight %}

Die Methode `->getopts()` liest die übergebenen Argumente in das Objekt
`np` ein. Diese werden dann in die Threshold-Variablen des np-Objektes
geschrieben.

{% highlight bash %}

if ($np->opts->warning \< $np->opts->critical ) {
        $np->nagios_exit(3, "Warning threshold darf nicht kleiner sein als Critical threshold.");
}

{% endhighlight %}

Die Exit-Methode mit dem Status 3 (UNKNOWN) wird aufgerufen, wenn der
Warning-Threshold kleiner ist als der Critical-Threshold.

{% highlight bash %}

my $content = get $url;
if ($content !\~ m/\^\d+\.\d{3}$/) {
        $np->nagios_exit(3, "Fehler beim Abrufen des Guthabens von SMSTrade.de!");
}

{% endhighlight %}

Holt den Zahlenwert von der URL ab (`get` ist eine LWP-Methode). Sollte
dieser Wert nicht der Regex `\^\d+\.\d{3}$` (= ‘ein oder mehrere
Ziffern, ein Punkt, gefolgt von genau drei Ziffern’) entsprechen, bricht
das Script ebenfalls mit UNKNOWN ab.

{% highlight bash %}

$content = nearest('0.01', $content);

if ($content \< $np->opts->critical) {
        $np->add_message(CRITICAL, "Guthaben bei SMSTrade beträgt nur noch $content Euro (critical bei ".$np->opts->critical.").");
} else {
        if ($content \< $np->opts->warning) {
           $np->add_message(WARNING, "Guthaben bei SMSTrade beträgt nur noch $content Euro (warning bei ".$np->opts->warning.").")
        } else {
           $np->add_message(OK, "Guthaben bei SMSTrade beträgt $content Euro.")
        }
}

{% endhighlight %}

Rundet den erhaltenen Wert auf zwei Nachkommastellen und vergleicht ihn
mit den Threshold-Werten. Entsprechend wird per methode
`->add_message` der Exit-Status, sowie der Output des Plugins gesetzt.

{% highlight bash %}

$np->add_perfdata(
        label => 'Guthaben',
        value => $content,
        uom   => 'EUR',
        threshold => $np->threshold(),
);

{% endhighlight %}

Sorgt dafür, dass dem Output des Plugins noch Performancedaten im
korrekten Format angehängt werden.

{% highlight bash %}

$np->nagios_exit(
        $np->check_messages()
);

{% endhighlight %}

Wertet den `Messages`-Stack aus und beendet das Script mit dem
entsprechenden Exitcode und Output-String – fertig:

![](/assets/check_smstrade/service.png)

Und so sieht ein braver Nagios aus:

![](/assets/check_smstrade/graph.png)

FIXME

Das Plugin check_smstrade.pl steht
[hier](http://blog.simon-meggle.de/wp-content/uploads/2011/08/check_smstrade.txt)
zum Download bereit.
