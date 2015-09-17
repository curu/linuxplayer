#!/usr/bin/env perl
######################################
# find udp packet drop port
#
# Author: Curu Wong
# Date:   2014-10-20
######################################
use strict;
use warnings;

use Time::HiRes qw(time sleep);
use POSIX qw(strftime);


our $freq = 10;

#m_time()
#return current time str with millisecond 
sub m_time{
	my $t = time();
	my $t_str = strftime("%H:%M:%S", localtime($t));
	my $t_ms = sprintf(".%03d", ($t - int($t))*1000);
	return $t_str . $t_ms;
}


#kernel_support()
#check if kernel support udp socket drop counter
sub kernel_support{
        my $udp_file = '/proc/net/udp';
        open(my $fh, "<", $udp_file) or die "unable to open $udp_file:$!";
        my $head = <$fh>;
        close($fh);
        return $head =~ / drops /;
}

#get_udp_stat()
#return current udp socket queue length and udp drop count
sub get_udp_stat{
	my $udp_file = "/proc/net/udp";
	open(my $fh, "<", $udp_file) or die "unable to open $udp_file:$!";
	my @lines = <$fh>;
	close($fh);
	shift @lines; #discard head line
	my %stat = ();
	
	for my $line(@lines){
		$line =~ s/^\s+|\s+$//g; #remove extra blank
		my @r = split /[: ]+/, $line;
		my($local_port, $st, $recv_queue, $inode, $udp_drop) = @r[2,5,7,13,16];
		next if $st ne "07"; #skip non listen socket
		$local_port = hex($local_port);
		#append inode number to port, avoid port reuse problem
		$local_port = sprintf "%d(inode:%s)", $local_port, $inode;
		$stat{$local_port} = [$recv_queue, $udp_drop];
	}
	return \%stat;
}

#main
if (! kernel_support() ){
        print STDERR "kernel not supported, must be 2.6.29 or newer\n";
        exit(1);
}

my $last_stat = get_udp_stat();
while(1){
	sleep(1/$freq);
	my $cur_stat = get_udp_stat();
	my $ts = m_time();
	for my $port ( keys %$cur_stat){
		#skip socket not listen anymore
		next unless exists $last_stat->{$port};
		my $last_drop = $last_stat->{$port}->[1];
		my $cur_drop = $cur_stat->{$port}->[1];
		my $cur_q_len = hex($cur_stat->{$port}->[0]);
		my $drop_inc = $cur_drop - $last_drop;
		if ($drop_inc > 0){
			printf "[%s]port:%s recv_queue_len:%s udp_drop:%s\n", 
				$ts, $port, $cur_q_len, $drop_inc;
		}
	}
	$last_stat = $cur_stat;
}
