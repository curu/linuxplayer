#!/usr/bin/perl
use strict;
use warnings;

our %process_of_shm = ();
our %shm_of_process = ();

#parse lsof to search for shm usage
open(my $lsof, 'lsof -P -n|') or die "unable to run lsof";
while(<$lsof>){
	my @fields = split;
	my $shm_key = $1 if $fields[-1] =~ m:^/SYSV(\S+):;
	if($shm_key){
		$shm_key = "0x$shm_key";
		my $pid = $fields[1];
		my $exec = readlink("/proc/$pid/exe");
		push @{ $process_of_shm{$shm_key} }, $exec;
	}
}
close($lsof);

print "#" x 80, "\n";
print "shm attach process list, group by shm key\n";
print "#" x 80, "\n\n";
for my $shm (sort {hex($a) <=> hex($b) } keys %process_of_shm){
	print "$shm:    ";
	my @processes = @{$process_of_shm{$shm}};

	my %seen; #you know, for uniq
	for my $p (sort @processes){
		if (!$seen{$p}++){
			print "$p " ;
			push @{ $shm_of_process{$p} }, $shm;
		}
	}
	print "\n";
}

print "\n\n","#" x 80, "\n";
print "process shm usage\n";
print "#" x 80, "\n";
for my $process (sort keys %shm_of_process){
	print "$process ";
	my @shm = sort { hex($a) <=> hex($b) } @{ $shm_of_process{$process} };
	print "[" ,scalar @shm, "]:    ";
	print "@shm", "\n";
}
