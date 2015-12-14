#!/usr/bin/perl
# (C) by Simon Meggle
# info (at) simon-meggle.de
# 
# Do THIS before using...
# mkdir /var/log/sendsms/
# mkdir /var/lock/sendsms/
# touch /var/log/sendsms/sendsms.log

# Your Key (given by your SMS provider; this works for smstrade.de. If you are using 
# another provider, you will have to change the HTTP request and its parameters.)
my $key		= "DEFINE ME";
my %group     = (
	"yourname"  		=> "49-y-o-u-r-n-u-m-b-e-r",
	"hisname"  		=> "49-h-i-s-n-u-m-b-e-r",
	# group
	"SystemAdmin" 		=> "yourname, hisname");

my $PATHNAME = "$0";
my $HOSTNAME=hostname();
my $SCRIPTNAME=`basename $0`;
my $LOG	= "/var/log/sendsms/sendsms.log";
my $LOCK = "/var/lock/sendsms";
my $DEBUG = "/var/log/sendsms/sendsms.debug";

#########################################################################
# don't change anything below
chdir;

use Getopt::Long qw(:config gnu_getopt);
use Sys::Hostname;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use URI::Escape;
use LWP::UserAgent;
use HTTP::Request::Common;

my $recipients;
my $file;
my $help            = 0;
my $verbose         = 0;
my $debug           = 0;
my $noop            = 0;
my $throttle        = undef;
my $throttle_by_tag = 0;
my $tag             = "sendsms";
my $account         = "sendsms";
my $listgroups      = 0;
my $throttled       = 0;
my $counter_string  = "";
my $message;

# SMS return codes
my %retvalue = (
	10		=> "ERROR: Receiver number not valid\n",
	20		=> "ERROR: Sender identification not valid; max 11 chrs allowed.\n",
	30		=> "ERROR: Message text not valid\n",
	31		=> "ERROR: Message type not valid\n",
	40		=> "ERROR: SMS route not valid\n",
	50		=> "ERROR: Identification failed\n",
	60		=> "ERROR: Not enough balance in account\n",
	70		=> "ERROR: Network does not support the route\n",
	71		=> "ERROR: Feature is not possible by the route\n",
	80		=> "ERROR: Handover to SMSC failed\n",
	100		=> "OK: SMS has been sent successfully\n",
	"OK"		=> "OK: SMS has been sent successfully\n"
);

getopts();
debug ("_____________8<____________________8<____________________8<_______________\n");
debug ("sendsms.pl - new run\n");

defined($sender) and ($HOSTNAME = $sender);

$message = substr( $message, 0, 150 );

$recipients = resolve_recipients($recipients);

open( LOG, "$LOG" ) or die "Could not open log file for reading: $LOG\n";

my @loglines = <LOG>;
close LOG;

# Set to noop if over quota
if ( throttle(@loglines) ) {
	$throttled = 1;
}

$message = $message . " " .$counter_string;
if ( sendsms( $HOSTNAME, $recipients, $message ) ) {
	exit 0;    # return success
}
else {
	exit 2;    # return failure
}

#########################################################################
# subs

sub resolve_recipients {
	my $recipients = shift @_;
	$recipients = fix_rcpts($recipients);
	while ( $recipients =~ m/[a-z]/ ) {
		$recipients = fix_rcpts($recipients);
	}
	return $recipients;
}

sub uniq(@) {    # return only sorted, uniqe entries from array passed
	my @a = @_;
	my %h;
	#printf( " Uniq input : %s \n ", Dumper( \@a ) ) if $debug;
	foreach (@a) {
		$h{$_} = 1 if ( $_ ne "" );
	}
	#printf( " Uniq output : %s \n ", Dumper( \%h ) ) if $debug;
	@a = sort( keys(%h) );
	return @a;
}

sub listgroups() {
	foreach ( sort keys(%group) ) {
		printf( " Group %s : \n ", $_ );
		foreach ( split( ", ", $group{$_} ) ) {
			printf( " \t %s \n ", $_ );
		}
	}
}

sub help() {
	print(" Usage : $0\n     -- recipients <rcpts> [ --file <file> ][ --throttle <amount,minutes> ][ --throttle-by-tag]\n");
	print("     [ --account <account_name>][ --tag <tag_name>][ --debug ][ --help][ --message <message> ] \n ");
	print(" \n ");
	print("Options:\n");
	print("--recipients | --rcpt | --r | -r | --group | --g | -g <rcpts> \n ");
	print("		sends message to group or recipient <rcpts> \n ");
	print("		<rcpts> can also be a list of groups or recipients (comma separated). \n");
	print("--sender | --from <sender> \n");
	print("		 Name of the sending instance (max 11 chrs). If not given, hostname is used instead. \n");
	print("--file | --f | -f <file> \n ");
	print("		 <file> is used as input. If -- file specifies \"-\" as the file,\n ");
	print("		 STDIN is used. If it is undefined and --message is specified,\n");
	print("		 the value of <message> is used. If both are left undefined,\n");
	print("		 STDIN is used\n");
	print("--message | --msg | --m | -m <message> \n");
	print("		 send message <message>, must not be used together with --file.\n");
	print("--listgroups|-- list | --l | -l \n ");
	print("		 list known aliases groups and exit \n");
	print("--noop | -n \n ");
	print("		 don't actually send anything.\n");
	print("--throttle <amount,minutes>\n");
	print("		 Throttles the delivery of either SMS in total or different tagged \n ");
	print("		 SMS( see --tag ) to prevent SMS spamming. If threshold \n ");
	print("		 is exceeded, 'this' SMS will be the last one sent. After that a \n ");
	print("		 broadcast SMS(hardcoded) will be sent to inform everybody that \n ");
	print("		 further SMS will be suppressed. SMS sending will be continued as soon \n");
	print("		 as threshold falls below --throttle.\n");
	print("		 Be advised to use --account for each independent application which \n ");
	print("		 wants to use sendsms. Otherwise, a 'spamming' application will also \n ");
	print("		 suppress messages of other applications. \n ");
	print("		 If --account is not specified, every SMS will be logged on \n ");
	print("		 account 'sendsms' (default). See --account for more details.\n");
	print("		 (Example: --throttle 50,15 => don't send more than 50 SMS per 15 minutes)\n");
	print("--throttle-by-tag \n");
	print("		 Use only with --throttle. This allows you to not throttle by number of SMS \n ");
	print("		 being sent, but by the number of messages with similar <tag>. For example, \n ");
	print("		 10 messages with tag 'nagios1' and 15 messages with tag 'nagios2', both \n ");
	print("		 with '--account=nagios' will then count as 2 messages.\n");
	print("--account <account_name>\n");
	print("		 Used by option-- throttle to determine the SMS throughput of a certain\n");
	print("		 application( think of that like a cost unit ) ( default : sendsms ).\n");
	print("--tag <tag_name>\n");
	print("		 To provide each message with a custom label, use --tag .\n\n");
	print("		 The following directories have to be present:\n");
	print("		    * /var/log/sendsms\n");
	print("		    * /var/lock/sendsms\n");
	
}

sub get_message($) {
	my $file = shift;
	if ( ( !defined($file) ) or ( $file == "" ) or ( $file == "-" ) ) {
		my $message = "";
		while (<STDIN>) {
			my $l = $_;
			chomp $l;
			$message .= $l . "\n";
		}
		return $message;
	}
	else {
		my $message = "";
		open INPUT, "<$file" || die("Unable to open $file for read: $!\n");
		while ( my $l = <INPUT> ) {
			chomp $l;
			$message .= $l . "\n";
		}
		return $message;
	}
	die("get_message: Oooops.\n");
}

sub getopts() {
	GetOptions(
		'debug|d'                     => \$debug,
		'file|f=s'                    => \$file,
		'help|h'                      => \$help,
		'recipients|rcpt|r|group|g=s' => \$recipients,
		'message|msg|m=s'             => \$message,
		'listgroups|list|l'           => \$listgroups,
		'noop|n'                      => \$noop,
		'account=s'                   => \$account,
		'throttle=s'                  => \$throttle,
		'throttle-by-tag'             => \$throttle_by_tag,
		'tag=s'                       => \$tag,
		'sender|from=s'                       => \$sender
	);
	if ($help) {
		help();
		exit 0;
	}
	if ($listgroups) {
		listgroups();
		exit 0;
	}
	if ( defined($message) and defined($file) and ( $file != "" ) ) {
		print( STDERR "You must not specify both file and message\n" );
		print( STDERR "\n" );
		help();
		exit 3;
	}

	if ( !defined($throttle) and ( $throttle_by_tag == 1 ) ) {
		print( STDERR "Option --throttle is missing.\n" );
		print( STDERR "\n" );
		help();
		exit 3;
	}

	if ( defined($throttle) and ( !$throttle =~ /[\d]+,[\d]+/ ) ) {
		print( STDERR "Wrong throttle format!\n" );
		print( STDERR "\n" );
		help();
		exit 3;
	}

	if ($debug) {
		open( DEBUG, ">>$DEBUG" ) or die "Can't write debug log to $DEBUG!\n";
	}

	if ( !defined($message) ) {
		$message = get_message($file);
	}
	else {
		$message =~ s/\\n/\n/g;
	}
}

sub debug {
	my $text = shift @_;
	print DEBUG time().".".$account.".".$tag . " $text";	
}

sub fix_rcpts($) {
	# fixup recipients, replace aliases by phone numbers
	# sort the list of recipients to only contain unique phone numbers
	my $rcpts_str = shift;
	my @rcpts = split( ",", $rcpts_str );
	my @newrcpts;
	#print "\@rcpts:\n" . Dumper( \@rcpts ) . "\n" if $debug;
	foreach (@rcpts) {
		my $rcpt = $_;
		if (  $rcpt !~ m/^[0-9+]*$/ ) {
			# looks like a group name
			if ( !defined( $group{$rcpt} ) ) {
				die("Undefined alias $rcpt\n");
			}
			else {
				$rcpt = $group{$rcpt};
			}
		}
		push @newrcpts, $rcpt;
	}
	$rcpts = join( ",", @newrcpts );
	#printf( "Newrcpts(before uniq): %s\n", Dumper( \@newrcpts ) ) if $debug;
	@newrcpts = uniq( split( ",", $rcpts ) );
	#printf( "Newrcpts: %s\n", Dumper( \@newrcpts ) ) if $debug;
	return ( join( ";", @newrcpts ) );
}

sub sendsms($$$) {
	my $from	= shift;
	my $rcpts       = shift;
	my @rcpts_array = split( ";", $rcpts );
	my $msg         = shift;
	my $host        = "gateway.smstrade.de";
	my $bulkhost        = "gateway.smstrade.de/bulk/";

	# Error/Throttle handling
	open( LOG, ">>$LOG" ) or die "Could not open log file for writing: $LOG\n";
	if ($noop) {
		# don't log if noop
		printf("EXITING: Nothing has been sent (--noop).\n");
		return 1;
	}
	if ( $msg eq "" ) {
		printf("EXITING: Nothing has been sent - message is empty.\n");
		return 0;
	}
	if ($throttled) {
		printf("EXITING: Nothing has been sent - throttle for account $account is active.\n");
		foreach (@rcpts_array) {
			print LOG time() . "\t$account\t$tag\t$_\tTHROTTLED\t$counter_string\t$msg\n";
		}
		return 0;
	}

	debug  "Sending Message:\n";
	debug "   From: $from\n";
	debug "   To: $rcpts\n";
	debug "   Message (max. 150 char): '$msg'\n";

	if (scalar(@rcpts_array) > 1) { $host = $bulkhost }

	my $ua = LWP::UserAgent->new();
	my $res = $ua->request (
	  POST "http://$host",
	  Content_Type	=> 'application/x-www-form-urlencoded',
	  Content	=> [ 	'key' 	=> $key,
				'from'	=> $from,
				'to'	=> $rcpts,
				'message' => $msg,
				'route'	=> "gold" ]
	);
	if ($res->is_error) { debug ("HTTP ERROR!!") }

	my $ret = $res->content;
	chomp $ret;    # remove trailing newlines if any

	printf( STDERR "$retvalue{$ret}" );
	debug ("$retvalue{$ret} (to $rcpts)\n");
	foreach (@rcpts_array) {
		print LOG time() . "\t$account\t$tag\t$_\t$ret\t$counter_string\t$msg\n";
	}
	return ($ret == 100 or $ret eq "OK" ) ;
	close LOG;
}

sub throttle {
	my @loglines = @_;
	my ( $unit, $minutes, );
	my $throttle_bytag = "";
	my $result = 0;    # don't throttle in case of doubt
	my $counter = 0;
	if ( ( defined $throttle ) and ( $throttle =~ /([\d]+),([\d]+)/ ) ) {
		$unit    = $1;
		$minutes = $2;
		my $rangestart = time() - $minutes * 60;
		debug ("Calculating throttle between " . $rangestart . " and " . time() . " (" . ( $minutes * 60 ) . " sec)...\n");

		my @range_result;
		foreach (@loglines) {
			my @elements = split( /\t/, $_ );
			if ( ( $elements[0] >= $rangestart ) and ( $elements[1] eq $account ) ) {
				push( @range_result, $elements[2] );
			}
		}
		# 
		if ($throttle_by_tag) {
			@range_result = uniq(@range_result);
			$throttle_bytag = "-by-tag";
			$counter = scalar(@range_result);
			# Wenn Tag nicht gefunden wird => counter++
			if (! grep $_ eq $tag, @range_result) { $counter++ }
		} else {
			# don't count tags - its a new message anyway... 
			$counter = scalar(@range_result) + 1 
		}

		$counter_string = "($counter;$unit)";
		# evaluation
		if ( $counter >= $unit ) {
			# enable throttle, create lockfile
			$result = 1;
			if ( !-e "$LOCK/$account.lock" ) {
				debug ("Throttle$throttle_bytag for account $account has to be enabled ($counter counts/$minutes minutes; throttle$throttle_bytag at $unit counts).\n");
				debug ("Trying to create lockfile $LOCK/$account.lock...\n");
				open LOCKFILE, ">$LOCK/$account.lock" or die " ...creating lockfile failed!!\n";

#				sendsms( $HOSTNAME, resolve_recipients("SystemAdmin"), "WARNING: $account on $HOSTNAME stops temporarily sending SMS; throttle$throttle_bytag is ENABLED ($counter counts/$minutes minutes; throttle$throttle_bytag at $unit counts)."	);
				sendsms( $HOSTNAME, resolve_recipients("SystemAdmin"), "WARNING: stopping temporarily sending SMS.");
			}
			else {
				debug ("Throttle$throttle_bytag for account $account is STILL enabled ($counter counts/$minutes minutes; throttle$throttle_bytag at $unit counts).\n");
			}
		}
		else {
			# disable throttle, delete lockfile
			$result = 0;
			debug ("No throttle$throttle_bytag for account $account neccessary ($counter counts/$minutes minutes; throttle$throttle_bytag at $unit counts).\n");
			if ( -e "$LOCK/$account.lock" ) {
				debug ("Found lockfile $LOCK/$account.lock. Trying to delete...\n");
				if ( unlink("$LOCK/$account.lock") ) {
					debug ("    deleted successfully!\n");
				}
				else {
					debug ("    failed!\n");
				}

			}
		}

	}
	else {

	}
	return $result;
}

#---------------------------------------------


