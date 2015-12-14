#!/usr/bin/perl

# (C) 2011 by Simon Meggle
# http://blog.simon-meggle.de

# Prüft das Guthaben bei SMStrade.de

use Nagios::Plugin;
use LWP::Simple;
use Math::Round qw/nearest/;


my $url = "http://gateway.smstrade.de/credits/?key=###YOURKEY###";

*Nagios::Plugin::Functions::get_shortname = sub {
	return undef;
};

my $np = Nagios::Plugin->new(
	shortname => 'check_smscredit',
	usage 	=> 'Usage: %s [-w|--warning=<Warning Betrag>] [-c|--critical=<Kritischer Betrag>]',
	blurb	=> 'Prüft das Guthaben bei SMSTrade und schlägt Alarm, wenn dieses unter die zulässigen Grenzwerte fällt, um rechtzeitig neues Guthaben zu überweisen.',
);


$np-> add_arg(
	spec	=> 'warning|w=i',
	help	=> 'Warning threshold.',
#	required => 1,
	default => 10,
);

$np->add_arg(
	spec	=> "critical|c=i",
	help 	=> 'Critical threshold.',
#	required => 1,
	default => 5,
);

$np->getopts();
$np->set_thresholds(
	warning => ($np->opts->warning() ),
	critical => ($np->opts->critical() ),
);

if ($np->opts->warning < $np->opts->critical ) {
	$np->nagios_exit(3, "Warning threshold darf nicht kleiner sein als Critical threshold.");
}

my $content = get $url;
if ($content !~ m/^\d+\.\d{3}$/) {
	$np->nagios_exit(3, "Fehler beim Abrufen des Guthabens von SMSTrade.de!");
}


$content = nearest('0.01', $content);

if ($content < $np->opts->critical) {
	$np->add_message(CRITICAL, "Guthaben bei SMSTrade beträgt nur noch $content Euro (critical bei ".$np->opts->critical.").");
} else {
	if ($content < $np->opts->warning) {
	   $np->add_message(WARNING, "Guthaben bei SMSTrade beträgt nur noch $content Euro (warning bei ".$np->opts->warning.").")
	} else {
	   $np->add_message(OK, "Guthaben bei SMSTrade beträgt $content Euro.")
	}
}


$np->add_perfdata(
	label => 'Guthaben',
	value => $content,
	uom   => 'EUR',
	threshold => $np->threshold(),
);

$np->nagios_exit(
	$np->check_messages()
);
