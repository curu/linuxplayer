#!/usr/bin/perl
##############################################################
# kill program if its mtime is later than proces start time
# 
# Author: Curu Wong
# Date:   2013-05-08
# License: GPL v3
# #############################################################
use strict;
use warnings;

use File::Basename;
use File::Glob ':glob';
use File::stat;
use POSIX;

#get_start_time($pid)
sub get_start_time{
	my $pid = shift;
	my $clock_ticks = POSIX::sysconf( &POSIX::_SC_CLK_TCK );
	#get system uptime
	my $c;
	local($/);
	open(my $fh1, "<", "/proc/uptime") or die "unable to get uptime";
	$c = <$fh1>;
	close($fh1);
	my $uptime = (split /\s+/, $c)[0];
	#get process start time tick since boot
	my $proc_stat = "/proc/$pid/stat";
	open(my $proc_fh, "<", $proc_stat) or die "unable to get proc stat";
	$c = <$proc_fh>;
	close($proc_fh);
	my $run_ticks = (split /\s+/, $c)[21];
	my $real_start_time = time() + $run_ticks/$clock_ticks  - $uptime;

	return $real_start_time;
}

my ($exe_prefix) = @ARGV;
if(!$exe_prefix){
	print STDERR "smart_kill.pl: kill process if program changed after start\n\n";
	print STDERR "Usage: smart_kill.pl <path>\n";
	print STDERR "eg:\n    smart_kill.pl /usr/local/app\n";
	exit(1);
}

my %process_to_kill;
for my $proc_exe (bsd_glob('/proc/[1-9]*/exe')){
	my $pid = $1 if $proc_exe =~ /(\d+)/;
	my $exe = readlink($proc_exe);
	next unless $exe && $exe =~ /^\Q$exe_prefix\E/;
	$exe =~ s/ \(deleted\)$//; #remove trailing possible '(deleted)' string
	my $exe_name = basename($exe);
	next if $process_to_kill{$exe_name};

	my $exe_mtime = lstat($exe)->mtime;
	my $start_time = get_start_time($pid);
	if($start_time < $exe_mtime){
		print "'$exe' changed after start, about to kill\n";
		$process_to_kill{$exe_name}++;
	}
}
my @to_kill = keys %process_to_kill;
qx(killall -9 @to_kill) if @to_kill;


