#!/usr/bin/perl
#################################################################################
#				Q1 Labs INC					#
#										#
#Author: Amer Hassounah								#
#Date Created: July 16, 2009							#
#Version: 0-1									#
#										#
#Date Last Modified: November 2012 27						#
#Modified by: Rudy Tan - rudy.tan@nl.ibm.com							#
#################################################################################


use strict;
use Getopt::Std;
use POSIX qw(strftime);

#Call getopts function to declare which options we're using
getopts('ghDd:S:c:m:');
#Declare getopts variables
our ($opt_h, $opt_d, $opt_S, $opt_D, $opt_c, $opt_g, $opt_m);


#flush output
$| =1;

#catch kill signals
$SIG{QUIT} = \&got_sig;
$SIG{INT} = \&got_sig;
$SIG{TERM} = \&got_sig;

#declare and initialize global variables
my $prev_manufacturer = "m";
my $prev_device = "d";
my $log_counter = 0;
my $baseIP;
my $device_counter = 1;
my @children = ();
my $output = "/dev/null";
if ($opt_g){$output = "/tmp/runAll.log";}
my $line_count = 0;
my $status = "running";
my $sql_string;

sub usage()
{
print "\n";
print "USAGE:   ./runAllSanitized.pl -d destination [-S spoof IP]\n";
print "-h		: Print this help message and exit\n";
print "-d destination	: Destination IP/Hostname (Required and must be in the 172.16.0.0/16 CIDR)\n";
print "-S spoof IP	: IP that will be used as a base IP to spoof IPs, \n";
print "		  if not specified a random base IP is generated\n";
print "\n";
}

#print usage block if -h option is specified and exit
if ($opt_h){
        usage();
        exit 0;
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
                        $sql_string = 'UPDATE log_runs SET status="'.$_[0].'", end_time="'.$db_time.'" WHERE id="'.$opt_m.'";';
                }

                #Run database update statement
                system ("mysql -e '$sql_string' -u phpuser --password=qat3stm3 log_server") == 0 or die "ERROR: '$sql_string' failed: $!";
                #print &get_time_stamp."INFO: Updated record id $opt_m with '$sql_string'\n";
        } else {
                #print &get_time_stamp."WARNING: Database ID was not found, database not updated!\n"
        }

}

#check if destination argument is a valid IP or a resolvable host
if ($opt_d eq '' or substr($opt_d,0,1) eq '-')
{
	#print &get_time_stamp."ERROR: Invalid destination or destination not specified.\n";
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
			#print &get_time_stamp."ERROR: Could not resolve destination hostname \"$opt_d\".\n";
			usage();
        		if ($opt_m){
                		$status = "errored";
                		update_db($status);
		        }
			exit 1;
		}elsif ($resolvedHost !~ /Address: 172\.16\.\d{1,3}\.\d{1,3}/){
			#print &get_time_stamp."ERROR: Resolved IP is not in the 172.16.0.0/16 CIDR.\n";
			usage();
			if ($opt_m){
                		$status = "errored";
                		update_db($status);
		        }
			exit 1;
		}else {#print &get_time_stamp."INFO: Destination $resolvedHost";}
	}
 }
}

##check if the destination server is alive using an nmap ping scan
#my $nmapOutput = `nmap -sP $opt_d | grep Host`;
#if ($nmapOutput !~ /Host .* appears to be up/){
#	print &get_time_stamp."ERROR: Destination server doesn't seem to be alive or is unreachable.\n";
#	usage();
#        if ($opt_m){
#                $status = "errored";
#                update_db($status);
#        }
#	exit 1;
#}

#check if the destination server is alive using a traceroute and nmap if trace fails
my $traceOutput = `traceroute -w 2 -m 5 $opt_d | grep $opt_d`;
if ($traceOutput !~ /$opt_d/){
	my $nmapOutput = `nmap -sP $opt_d | grep Host`;
	if ($nmapOutput !~ /Host .* is up/){
		#print &get_time_stamp."ERROR: Destination server doesn't seem to be alive or is unreachable.\n";
        	usage();
        	if ($opt_m){
        		$status = "errored";
        	        update_db($status);
        	}
        	exit 1;
	}
}

#check if the Spoof IP is valid 
if ($opt_S){
	if ($opt_S !~ /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/){
		#print &get_time_stamp."ERROR: Spoof IP supplied, $opt_S, is not a valid IP address.\n";
		usage();
        	if ($opt_m){
                	$status = "errored";
        	        update_db($status);
	        }
		exit 2;
	} else {
		$baseIP = $1.".".$2.".".$3.".";
		$device_counter = $4;
	}
} else {
	my $range = 254;
	my $min = 1;
	my $baseIP1 = int(rand($range))+$min;
	my $baseIP2 = int(rand($range))+$min;
	my $baseIP3 = int(rand($range))+$min;
	$baseIP = $baseIP1.".".$baseIP2.".".$baseIP3.".";
}

#check if the count argument is a whole number if it's passed
if ($opt_c)
{
	if ($opt_c !~ /^\d+$/ ) {
		#print &get_time_stamp."ERROR: Count must be an integer\n";
		usage();
		if ($opt_m){
                	$status = "errored";
        	        update_db($status);
	        }
        	exit 3;
	}
}
##Amer: added a label so we can use the perl goto function
START:
open ALL, "find /labfiles/events/ -name \"*.syslog\" -type f |" or die $!;
while (<ALL>){
	#check if device counter is greater than 254 and set it back to 1 so the spoof ip can loop back
	if ($device_counter > 254) {$device_counter = 1;}
	#extract the manufacturer, device and log file information 
        my $in = $_;
        $in =~ s/\n$//;
        $in =~ m/\/labfiles\/events\/([\w-]+)\/([\w-]+)\/([\w-]+\.syslog)/;
        my $cur_manufacturer = $1;
        my $cur_device = $2;
        my $cur_log = $3;
	
	#check the number of events in the log file and set the counter to 1000 if the number of events is less than 1000
	if ($opt_c) {
		$line_count = $opt_c;
	}else{
		my $wcOut = `wc -l $in`;
        	$wcOut =~ m/^(\d+)\s/;
        	$line_count = $1;
		if ($line_count < 1000){$line_count=1000;}
	}

	#check if we're still processing the same manufactuer
        if ($cur_manufacturer eq $prev_manufacturer){
		#check if we're still sending logs for the same device and increment the log counter
                if ($cur_device eq $prev_device){
                        $log_counter++;
                }else {
		#since the device changed print prev device info, reset log counter and increment device counter
                        if ($log_counter > 0) {
                                #print &get_time_stamp."INFO: Sent $log_counter $prev_device logs\n";
                        }
                        $log_counter = 1;
                        $device_counter++;
                        #print "INFO: Now reading $cur_device logs\n";
                }
        } else {
	#manufacturer changed, print prev man info, reset log counter and increment device counter
                if ($log_counter > 0) {
                        #print &get_time_stamp."INFO: Sent $log_counter $prev_device logs\n";
                }
                $log_counter = 1;
                $device_counter++;
                #print "INFO: Processing $cur_manufacturer devices\n";
                #print "INFO: Reading $cur_device logs\n";
        }
	
	#set previous manufacturer and device to current values
        $prev_manufacturer = $cur_manufacturer;
        $prev_device = $cur_device;

	#fork children to run the logs
	my $pid = fork();
	if ($pid){
		#parent process, push child's pid on the array
		push(@children, $pid);
	} elsif ($pid==0) {
	#start child
	#run the log
#	my $cmd_string = "amer3000.pl -d $opt_d -n -c $line_count -S ".$baseIP.$device_counter." -f $in >> testRun.log";
#	$line_count=100;

#Amer: modified the command string to adjust the event rate to 1
	my $cmd_string = "amer3000.pl -s 1 -d $opt_d -nN -c $line_count -S ".$baseIP.$device_counter." -f $in > $output";
	#print &get_time_stamp."RUN: $cmd_string\n";
	#execute the command string to send the log if not running in debug mode
	if (!$opt_D){
		#close(STDOUT);
		system($cmd_string);
	}
	#make sure the child exits after it's done otherwise we end up with an exponential fork bomb
	exit 0;
	#end child
	} else {
	#Amer: following your example I modified the script to wait for children to die then we go back to start
		#print &get_time_stamp."INFO: System ran out of resources, waiting for resources to free up before starting again...";
		foreach (@children){
		#print ".";
		waitpid($_,0);
		}
#set filepointer to the beginning of ALL
		seek (ALL,0,0);
		goto START;
	}
}
#print &get_time_stamp."INFO: Sent $log_counter $prev_device logs\n";


#wait for children to finish running
#print &get_time_stamp."INFO: Waiting for children to finish running...";
#foreach (@children){
#	print ".";
#	waitpid($_,0);
#}
#print "\n".&get_time_stamp."END\n";
#if ($opt_m){
#        $status = "completed";
#        update_db($status);
#}
#Amer: we finished everything so we go back to START and start all over again
my $kill_string = "ps -ef | grep amer3000.pl | grep -v grep | awk '{print \$2}' | xargs kill -9";
#print &get_time_stamp."Kill eventgen after 4 hours  $kill_string\n";
sleep (4*3600);
#execute the command string to send the log if not running in debug mode
if (!$opt_D){
	#close(STDOUT);
	system($kill_string);
}
#set filepointer to the beginning of ALL
seek (ALL,0,0);
goto START;
exit 0;



#reaper function to capture kill signals and kill off the children
sub got_sig
{
	#print "\n";
        #print &get_time_stamp."TERMINATE: Recieved termination signal ".$_[0]."\n";
        #print &get_time_stamp."TERMINATE: Killing children processes\n";
		#close ALL before die
		close ALL;
        foreach (@children){
                if (checkPid($_)){
                        system("kill $_");
                }
        }
        #print &get_time_stamp."END\n";
	if ($opt_m){
                $status = "killed";
                update_db($status);
        }
        exit 255;
}

#copied from Greg Davis and modified to our needs
#check if the child pid is running and it's ours
sub checkPid
{
        my $pid = $_[0];
        #if pid doesn't exist return 0
        if (! -e "/proc/$pid/cmdline"){return 0;}
        else {
                my $commandName = `cat /proc/$pid/cmdline`;
                #if pid matches my command return 1 so we kill it else return 0 since it's not our pid
                if ($commandName =~ /amer3000\.pl \-d $opt_d \-n \-c/){
                        return 1;
                }else {return 0;}
        }
}

# Display a formatted timestamp
sub get_time_stamp() {
        my $time_stamp = strftime "%b %e %H:%M:%S", localtime;
        $time_stamp = $time_stamp." ";
	return $time_stamp;
}

