#!/usr/bin/perl
###################################################################
#who_attach_shm.pl:  list shared memory keys and attaching program
#
#Author: 	Curu Wong
#Date:   	2013-04-04
#License: 	GPL v3
###################################################################
use strict;
use warnings;

use File::Glob ':glob';

our %process_of_shm = ();
our %shm_of_process = ();

#parse /prc/[pid]/maps for shm usage
for my $proc_map (bsd_glob('/proc/[1-9]*/maps')){
	my $pid = (split /\//, $proc_map )[2];
	open(my $fh, "<", $proc_map) or die "unable to open '$proc_map':$!";
	while(<$fh>){
		my $shm_key = $1 if $_ =~ m:\s+/SYSV(\S+):;
		if($shm_key){
			$shm_key = "0x$shm_key";
			my $exec = readlink("/proc/$pid/exe");
			push @{ $process_of_shm{$shm_key} }, $exec;
		}
	}
	close($fh);
}

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
