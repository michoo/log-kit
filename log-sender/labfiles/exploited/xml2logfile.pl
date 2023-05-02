#!/usr/bin/perl
while(<>){
	chomp();
	my ($base64line) = /<payloadAsBase64>(.*?)<\/payloadAsBase64>/; 

	if ($base64line ne ""){
		my $ascii = `echo '$base64line' | base64 -d`;
		chomp($ascii);
		print "$ascii\n";
	}
}

