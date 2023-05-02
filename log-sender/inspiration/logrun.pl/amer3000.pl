#!/usr/bin/perl
#################################################################################
#				Q1 Labs INC					#
#										#
#Author: Amer Hassounah								#
#Date Created: January 16, 2009							#
#Version: 0-13									#
#										#
#Date Last Modified: June 05 2009						#
#Modified by: Amer Hassounah							#
#################################################################################

use strict;
use Getopt::Std;
use IO::Socket;
use Net::RawIP;
use POSIX qw(strftime);
use Time::HiRes qw(usleep gettimeofday);

#Define getopts function to accept switched arguments
getopts('vlgnNuTd:h:f:c:t:s:m:S:p:k:');
#define getopts variables
our($opt_v, $opt_l, $opt_d, $opt_h, $opt_f, $opt_c, $opt_t, $opt_g, $opt_s, $opt_n, $opt_m, $opt_u, $opt_T, $opt_S, $opt_N, $opt_p, $opt_k);

#declare some variables
my $SLEEP_AFTER = 10;
my $SEND_COUNT = 1;
my $timestamp= `date`;
my $user = `whoami`;
$user =~ s/\n//;
print &get_time_stamp."RUNNING: Running as user $user\n";
my $status = "running";
my $sql_string="";
my $gunzip_file;
#$gcount is the event counter, incremented everytime an event is sent
my $gcount = 0;
my $startseconds =0;
my $startmicroseconds =0;
my $endseconds =0;
my $endmicroseconds =0;

#set it to flush output after every print statement. 
$| = 1; 

#catch kill signals
$SIG{QUIT} = \&got_sig;
$SIG{INT} = \&got_sig;
$SIG{TERM} = \&got_sig;
  

#usage sub
sub usage()
{
print "\n";
print "USAGE:	./amer3000.pl -d destination -f file [-vuln] [-p port] [-h host] [-c count] [-t time] [-s eps rate]\n";
print "-u		: Print this usage message and exit\n";
print "-v		: Verbose mode on (default off)\n";
print "-l		: Loop indefinitely\n";
print "-n		: No noise mode (default off, overrides verbose)\n";
print "-T		: use tcp connection (default is udp)\n";
print "-d destination	: Destination IP/Hostname (Required and must be in the 172.16.0.0/16 CIDR)\n";
print "-h host		: Device Hostname/IP (default will not attach a header)\n";
print "-f file		: Event filename (Required)\n";
print "-c count	: Number of events to send (overrides loop)\n";
print "-t time		: Time in seconds to send events (default not limited)\n";
print "-s eps rate	: Number of events to send per second (default 10)\n";
print "-S spoofed IP	: IP that will be used to spoof the source IP\n";
print "-p port		: Port number to send the events on (default 514)\n";
print "-k % Corrupted	: Percentage of desired corrupted events (acceptable values 1-99)\n";
print "\n";
}

#debug sub prints out passed in parameters and other useful infor for debugging
sub debug()
{
print "###########################################################################\n";
print "BEGIN DEBUG\n";
print "-v verbose :$opt_v\n";
print "-l loop :$opt_l\n";
print "-n no noise :$opt_n\n";
print "-T tcp:$opt_T\n";
print "-d destination :$opt_d\n";
print "-h host :$opt_h\n";
print "-f filename :$opt_f\n";
print "-c count :$opt_c\n";
print "-t time :$opt_t\n";
print "-s sleep after :$opt_s\n";
print "-m mysql id :$opt_m\n";
print "-u usage :$opt_u\n";
print "END DEBUG\n";
print "###########################################################################\n";
}

#update db sub, only runs if user is apache
sub update_db
{
        if ($opt_m){
		#Format the time as YYYY-MM-DD HH:MM:SS
		my $db_time = `date +%F%t%T`;
		$db_time =~ s/\s$//;
		$db_time =~ s/\t/ /g;

		#Construct database update string
		if ($_[0] eq 'running') {
			$sql_string = 'UPDATE log_runs SET status="running", pid="'.$$.'", start_time="'.$db_time.'" WHERE id="'.$opt_m.'";';
		} else {
        		$sql_string = 'UPDATE log_runs SET status="'.$_[0].'", events_sent="'.$gcount.'", end_time="'.$db_time.'" WHERE id="'.$opt_m.'";';
		}
	
		#Run database update statement
		system ("mysql -e '$sql_string' -u phpuser --password=qat3stm3 log_server") == 0 or die "ERROR: '$sql_string' failed: $!";
		print &get_time_stamp."INFO: Updated record id $opt_m with '$sql_string'\n";
        } else {
        	print &get_time_stamp."WARNING: Database ID was not found, database not updated!\n"
        }
	
}

#print usage block if -u option is specified and exit
if ($opt_u){
	usage();
	exit 0;
}

#execute debug sub if flag is set
if ($opt_g)
{
        debug();
}

#check if destination argument is empty and exit if it is
if ($opt_d eq '' or substr($opt_d,0,1) eq '-')
{
	print &get_time_stamp."ERROR: Invalid destination or destination not specified.\n";
	usage();
	if ($opt_m){
        	$status = "errored";
        	update_db($status);
	}
	exit 1;
}else{
        if ($opt_d !~ /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/){
                my $resolvedHost = `nslookup $opt_d | grep -v 172.16.60.200 | grep -v 172.16.50.200 | grep -P \"^Address:\"`;
                if ($resolvedHost !~ /Address: \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/){
                        print &get_time_stamp."ERROR: Could not resolve destination hostname \"$opt_d\".\n";
                        usage();
			if ($opt_m){
		                $status = "errored";
                		update_db($status);
        		}
                        exit 1;
                }elsif ($resolvedHost !~ /Address: 172\.16\.\d{1,3}\.\d{1,3}/){
                        print &get_time_stamp."ERROR: Resolved IP is not in the 172.16.0.0/16 CIDR.\n";
                        usage();
                        if ($opt_m){
                                $status = "errored";
                                update_db($status);
                        }
                        exit 1;
                }else {print &get_time_stamp."INFO: Destination $resolvedHost";}
        }
}

##check if the destination server is alive using an nmap ping scan
#if (!$opt_N){
#	my $nmapOutput = `nmap -sP $opt_d | grep Host`;
#	if ($nmapOutput !~ /Host .* appears to be up/){
#	        print &get_time_stamp."ERROR: Destination server doesn't seem to be alive or is unreachable.\n";
#	        usage();
#	        if ($opt_m){
#	                $status = "errored";
#	                update_db($status);
#	        }
#	        exit 1;
#	}
#}

#check if the destination server is alive using a traceroute and nmap if trace fails
if (!$opt_N){
        my $traceOutput = `traceroute -w 2 -m 5 $opt_d | grep $opt_d`;
        if ($traceOutput !~ /$opt_d/){
                my $nmapOutput = `nmap -sP $opt_d | grep Host`;
		if ($nmapOutput !~ /Host .* is up/){
			print &get_time_stamp."ERROR: Destination server doesn't seem to be alive or is unreachable.\n";#
	                usage();
	                if ($opt_m){
	                        $status = "errored";
	                        update_db($status);
	                }
	                exit 1;
		}
        }	
}


#check if filename argument is empty and exit if it is
if ($opt_f eq '' or substr($opt_f,0,1) eq '-')
{
	print &get_time_stamp."ERROR: Invalid filename or filename not specified.\n";
	usage();
        if ($opt_m){
                $status = "errored";
                update_db($status);
        }
        exit 1;
}
#check if the count argument is a whole number if it's passed
if ($opt_c)
{
	if ($opt_c !~ /^\d+$/ ) {
		print &get_time_stamp."ERROR: Count must be an integer\n";
		usage();
        	if ($opt_m){
        	        $status = "errored";
        	        update_db($status);
        	}
        	exit 1;
	}
	else{
		$opt_l = $opt_c;
	}
}
#check if the time argument is a whole number if it's passed
if ($opt_t)
{
	if ($opt_t !~ /^\d+$/ ) {
		print &get_time_stamp."ERROR: Time must be an integer\n";
		usage();
	        if ($opt_m){
	                $status = "errored";
	                update_db($status);
	        }
	        exit 1;
	}

}

#check if the port argument is a whole number if it's passed
if ($opt_p)
{
        if ($opt_p !~ /^\d+$/ ) {
                print &get_time_stamp."ERROR: Port must be an integer\n";
                usage();
                if ($opt_m){
                        $status = "errored";
                        update_db($status);
                }
                exit 1;
        }

}

#check if the % corrupt value passed is an integer in 1-99
if ($opt_k)
{
        if ($opt_k !~ /^\d+$/ ) {
                print &get_time_stamp."ERROR: % Corrupted  must be an integer\n";
                usage();
                if ($opt_m){
                        $status = "errored";
                        update_db($status);
                }
                exit 1;
        }
	if ($opt_k < 1 || $opt_k > 99){
		print &get_time_stamp."ERROR: % Corrupted  must be an integer between 1 and 99\n";
                usage();
                if ($opt_m){
                        $status = "errored";
                        update_db($status);
                }
                exit 1;
	}
}

#check if the sleep after argument is a whole number
if ($opt_s)
{
        if ($opt_s !~ /^\d+$/ ) {
	        print &get_time_stamp."ERROR: Sleep After must be an integer\n";
	        usage();
	        if ($opt_m){
	                $status = "errored";
	                update_db($status);
	        }
	        exit 1;
        }
	else{
		$SLEEP_AFTER = $opt_s;
	}
}

#if spoof IP is specified check to see if it's a valid IP
if ($opt_S){
	if ($opt_S !~ /^\d\d?\d?\.\d\d?\d?\.\d\d?\d?\.\d\d?\d?$/){
		print &get_time_stamp."ERROR: Spoof IP must be a valid IP address\n";
		usage();
		if ($opt_m){
                        $status = "errored";
                        update_db($status);
                }
                exit 1;
	}
}

#Open file if available otherwise die
#check for gzip format, and copy to temp dir and run that file if so - cleanup on file called on end
if ($opt_f =~ /.*\/(.+)\.(gz|gzip)$/i) {
  $gunzip_file = "/tmp/$1.".time;
  `gzip -d -c $opt_f > $gunzip_file`;
  open MSG, '<', $gunzip_file or die "ERROR: Failed to open '$opt_f' or '$gunzip_file'.\n";
} else {
  open MSG, '<', $opt_f or die "ERROR: Failed to open '$opt_f'.\n";
}



my $sockProto;
my $lineTerminator;
my $sock;
my $port="514";

#change the default port if parameter is passed
if ($opt_p){$port=$opt_p;}

# Opening socket
if (!$opt_S){
	$sockProto = 'udp';
	$lineTerminator = '';
	if($opt_T)
	{
		$sockProto = 'tcp';
		$lineTerminator = "\r";
	}
	$sock = new IO::Socket::INET
	(
	     PeerAddr => "$opt_d",
	     PeerPort => "$port",
	     Proto    => $sockProto
	);
} else {
	$sock = new Net::RawIP({udp =>{}});
	$sock->set({ip => {saddr => $opt_S , daddr => $opt_d , tos => 22} ,
		udp  => {source => 1337 , dest => $port}});
	$lineTerminator = '';
}
#set the socket to auto-flush every new line
select(SOCK);
$|=1;
select(STDOUT);

#collect time information for calculating time intervals
my $starttime = time;
my $currenttime = time;
my $difftime = $currenttime - $starttime;

#declare loop counter variables
#$i is loop counter (incremented after looping through the file completely)
my $i = 0;
#declare loop boolean and set to true if -l or -t option is specified
my $loop = $i<$SEND_COUNT;
if ($opt_l || $opt_t){
	$loop = 1;
}

print &get_time_stamp."RUNNING: Sending events... Start time: $timestamp";

# If the user is apache initialize the record in the db
if ($opt_m){
     	$status = "running";
        update_db($status);
}

while ($loop) 
{
    while (<MSG>) 
    {#read the file input line by line and send it
        my $send = $_;
	$send =~ s/\r\n?//;
        $send =~ s/\n//;
	$send = $send.$lineTerminator;
	#if user specified a host name then construct a header and attach it
        if($opt_h)

        {#construct a proper syslog header
            my $cdate = `date +%b%t%e%t%T`;
	    $cdate =~ s/\s+$//;
	    $cdate =~ s/\t/ /g;
	    $send = "<125>$cdate $opt_h $send";
        }
        
        $gcount++;


	#if a count limit is specified check for number of events sent already
	#exit if limit is reached
	if ($opt_c)
	{
		if ($gcount > $opt_c)
		{
			$currenttime = time;
	                $difftime = $currenttime - $starttime;
			close(MSG);
                        if (!$opt_S){close($sock);}
                        $timestamp = `date`;
                        print &get_time_stamp."END: Event limit reached, $opt_c events, end time: $timestamp";
                        $gcount--;
			print &get_time_stamp."END: Total events sent $gcount\n";
                        print &get_time_stamp."END: Total time to send events $difftime seconds\n";
                        if ($opt_m){
                                $status = "completed";
                                update_db($status);
                        }
                        exit 0;

		}
	}	
	#if a time limit is specified check how long event replay has been
	#running for and exit if time limit is reached
	if ($opt_t)
	{	
		$currenttime = time;
		$difftime = $currenttime - $starttime;
		if ($difftime >= $opt_t)
		{
			close(MSG);
			if (!$opt_S){close($sock);}
			$timestamp = `date`;
			print &get_time_stamp."END: Time limit reached, $opt_t seconds, end time: $timestamp";
			$gcount--;
			print &get_time_stamp."END: Total events sent $gcount\n";
			print &get_time_stamp."END: Total time to send events $difftime seconds\n";
			if ($opt_m){
        			$status = "completed";
        			update_db($status);
			}
			exit 0;
		}
	}
	
	#check and substitute events for corrupt events if set
	if ($opt_k) {
		if (($gcount % 100) < $opt_k){
			$send = "Corrupt Event $gcount".$lineTerminator;
		}
	}	

        #if verbose flag is set output in verbose mode
        if(!$opt_n){
                if($opt_v)
                {
                    print &get_time_stamp."INFO Sending: '$send'\n";
                }
        }

	#send the event
	if ($opt_S){
		#print "DEBUG: setting data in udp raw packet\n";
		$sock->set({udp => {data => $send}});
		#print "DEBUG: sending raw packet\n";
		$sock->send(0,1);
		#print "DEBUG: raw packet sent\n";
	}else{
        	$sock->send($send);
	}
        #sleep for the remainder of the second every $SLEEP_AFTER events
        if(($gcount % $SLEEP_AFTER) == 0)
        {
                ($startseconds, $startmicroseconds) =  gettimeofday;
                my $sleepfor = 1000000 - $startmicroseconds;
		usleep($sleepfor);
		#print "Slept for: ".$sleepfor."\n";
		#do{
                #        ($endseconds, $endmicroseconds) = gettimeofday;
                #}while(($endseconds-$startseconds)<1);

        }

    }
    $i++;
    #if the no noice option is not specified then print number of events sent so far	
    if (!$opt_n){
    	print &get_time_stamp."INFO: $gcount events sent...\n";
	}
    #move back to the begining of the file
    seek(MSG, 0, 0);
    #if loop option is not specified check for file counter to set loop boolean
    if (!$opt_l && !$opt_t){
	$loop = $i<$SEND_COUNT;
	}
}

# Display a formatted timestamp
sub get_time_stamp() {
        my $time_stamp = strftime "%b %e %H:%M:%S", localtime;
        $time_stamp = $time_stamp." ";
	return $time_stamp;
}

#SIG handler sub
sub got_sig
{
        close(MSG);
        if ($gunzip_file) {
          if (unlink($gunzip_file)) {
            print &get_time_stamp."CLEANUP: Removed $gunzip_file\n";
          } else {
            print &get_time_stamp."ERROR: Failed removing $gunzip_file\n";
          }
        }
        if (!$opt_S){close($sock);}
        $currenttime = time;
        $difftime = $currenttime - $starttime;
        $timestamp = `date`;
        print &get_time_stamp."END: Recieved termination signal ".$_[0]." at $timestamp";
        print &get_time_stamp."END: Total events sent $gcount\n";
        print &get_time_stamp."END: Total time to send events $difftime seconds\n";

        if ($opt_m){
                $status = "killed";
                update_db($status);
        }

        exit 0;
}

# Closing file and socket
close(MSG);
if ($gunzip_file) {
  if (unlink($gunzip_file)) {
    print &get_time_stamp."CLEANUP: Removed $gunzip_file\n";
  } else {
    print &get_time_stamp."ERROR: Failed removing $gunzip_file\n";
  }
}

if (!$opt_S){close($sock);}
$currenttime = time;
$difftime = $currenttime - $starttime;
$timestamp = `date`;
print &get_time_stamp."END: Event replay complete, end time: $timestamp";
print &get_time_stamp."END: Total events sent $gcount\n";
print &get_time_stamp."END: Total time to send events $difftime seconds\n";
if ($opt_m){
	$status = "completed";
	update_db($status);
}
exit 0;
