#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(.);

use Time::HiRes qw( usleep nanosleep gettimeofday tv_interval);

use Getopt::Std;
use Syslog;
use Date::Parse;

# Play back a log file

my $me = $0;
$me =~ s|.*/||;

# Option defautls
my %options = (
	d	=>	"127.0.0.1",	# host
	p	=>	514,		# port
	a	=>	0,		# adjust time
	v	=>	0,		# verbose
);

# Help
sub HELP_MESSAGE {
	print <<EOF;
$me [-d <host>] [-p <port>] <message file>
Options:
-d : destination syslog host (default $options{d})
-p : destination port (default $options{p})
-w : respect delays as seen in the message file.
-v : verbose
EOF
	exit 1;
}

getopts('vwd:p:', \%options);

unless (@ARGV > 1) {
	print STDERR "Need a syslog file name\n";
	HELP_MESSAGE;
}

my $file = shift @ARGV;

my $rate = shift @ARGV;

open MSG, '<', $file or die "Failed to open '$file'\n";
my @data = <MSG>;
close MSG;

my $syslog = new Syslog(
	name     => 'logreplay',	# overide this one in 'send'
	facility => 'local6',
	priority => 'info',
	loghost  => $options{d},
	port     => $options{p}
);

print STDOUT "Playing back '$file' to $options{d}:$options{p} ...\n";

my $time_adjustement = undef;

my $syslog_pattern = qr/^([[:upper:]][[:lower:]]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})\s+([\w\.]+)\s+(\w+)(?:\[(\d+)\])?:\s*/o;

my $count = 0;
my $i = 0;
my $host = "";
while (1) 
{
	while ($i < @data-1) 
	{
		my $startseconds=0;
		my $startmicroseconds=0;
		($startseconds, $startmicroseconds) =  gettimeofday;
		do
		{
			my $nogood = 0;
			if ($data[$i] =~ m#wolverine#)
			{
				$host = "wolverine";
			}
			elsif ($data[$i] =~ m#apophis#)
			{
				$host = "apophis";
			}
			else
			{
				$host = "";
				$nogood = 1;
			}		
		
			if ($nogood == 0)
			{
				$count++;
				$syslog->send($data[$i], host => $host, name => "", pid => "1");
			}
			$i++;
			if ($i > @data)
			{
				$i = 0;
			}
		} while ($count < $rate);

		my $endseconds=0;
		my $endmicroseconds=0;
		my $slept = 0;
		
		do 
		{
			($endseconds, $endmicroseconds) = gettimeofday;		

			my $sleeptimeA = $endseconds - $startseconds;
			my $sleeptime =0;

			if ($sleeptimeA < 1)
			{	
				$sleeptime = $endmicroseconds - $startmicroseconds;
				$slept += $sleeptime;
			}
			else
			{
				my $tmp = $startmicroseconds - $endmicroseconds;
				$sleeptime = 100000000000000000 - $tmp;
				$slept += $sleeptime;
			}

		} while ($slept < 300000000000000000);
		$count = 0;
	}
	$i = 0;
}



$syslog->close;
