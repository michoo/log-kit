#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw(.);

use Syslog;
use Time::HiRes qw( time sleep );
use Getopt::Std;

# create log entries at a fixed rate (n per sec)
# Option defautls

my $me = $0;
$me =~ s|.*/||;

my %options = (
	       d=>"127.0.0.1",# host
	       p=>514,# port
	       );

# Help
sub HELP_MESSAGE {
    print <<EOF;
$me [-d <host>] [-p <port>] <messages per second>
Options:
    -d : destination syslog host (default $options{d})
    -p : destination port (default $options{p})
EOF
exit 1;
}

getopts('d:p:', \%options);

unless (@ARGV) {
    print STDERR "Need an event rate\n";
    HELP_MESSAGE;
}

my $nmsg = shift @ARGV;

my $syslog = new Syslog(
			name     => 'lograte',# overide this one in 'send'
			facility => 'local6',
			priority => 'info',
			loghost  => $options{d},
			port     => $options{p},
			);

print STDERR "generating $nmsg messages per second to $options{d}:$options{p}\n";
print STDERR "Ctrl-c to stop\n";

#my $msg = "[1:486:2] ICMP Destination Unreachable (Communication with Destination Host is Administratively Prohibited) [Classification: Misc activity] [Priority: 3]: {ICMP} 172.16.60.36 -> 172.16.10.1";
my $msg = "09/30/2000 10:24:55 0 Security [12] RADIUS: \"gerardo\" access DENIED by server \"134.132.144.12\".";

# delay in microseconds
my $delay = 1.0/$nmsg;
my $burst = 1;
my $resolution = 0.2;
while ($delay < $resolution) {
    $burst++;
    $delay = $burst * 1.0 / $nmsg;
}


my $target = time + $delay;

my $cantkeepup = 0;

print "Sending $burst messages every ", int ($delay * 1000), "ms\n";
while (1) {
    for (my $i = 0 ; $i < $burst; $i++) {
	$syslog->send($msg);
    }
    my $now = time;
    my $wait = $target - $now;
    if ($wait > 0) {
	print "waiting for ", int($wait * 1000), "ms ...\n";
	sleep $wait;
    } else {
	if ($now >= $cantkeepup + 2) {
	    print "Can't keep up with requested rate\n";
	    $cantkeepup = $now;
	}
    }
    $target += $delay;
}
