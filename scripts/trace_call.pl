#!/usr/bin/perl
##############################################################################
#trace_call.pl: trace and log command call chain.
#Usage:
# 1. create a directory to hold your original command($orig_dir)
#    mkdir /usr/local/orig_bin
# 2. copy the program you want to trace call to $orig_dir, eg:
#    cp -a /bin/date /usr/local/orig_bin
# 3. overrite the program with trace_call.pl, eg:
#    cp /path/to/trace_call.pl /bin/date
#     chmod +x /bin/date
#
# Author : Curu Wong
# Date   : 2012-11-21
# License: GPL V2
################################################################################
use strict;
use warnings;
use Cwd qw(getcwd);
use File::Basename;
use POSIX qw(strftime);

my $orig_dir = "/usr/local/orig_bin";
my $trace_log = "/tmp/trace_call.log";

#get_cmdline($pid)
#return an array contain the cmdline of $pid
sub get_cmdline{
    my $pid = shift;
    open(my $proc, "<", "/proc/$pid/cmdline") or die "unable to read cmdline for pid $pid :$!";
    local $/; #slurp mode
    chomp(my $cmdline = <$proc>);
    close($proc);
    my @cmd = split /\0/, $cmdline;
    return \@cmd;
}

#my_getppid($pid)
#return ppid of $pid via looking at /proc filesystem 
sub my_getppid{
    my $pid = shift;
    open(my $proc_stat, "<", "/proc/$pid/stat") or die "unable to read stat for pid $pid :$!";
    local $/; #slurp mode
    chomp(my $stat = <$proc_stat>);
    close($proc_stat);
    #some variable not used now...
    my($my_pid, $comm, $state, $ppid) = split /\s+/, $stat;
    return int($ppid);
}

#get_call_tree($pid, \@call_tree)
#return a call tree for $pid in @call_tree;
sub get_call_tree{
    my $pid = shift;
    my $call_tree = shift;
    if ($pid == 1){
        return undef;
    }
    unshift @{$call_tree}, [$pid, get_cmdline($pid)];
    get_call_tree(my_getppid($pid), $call_tree);
}

#main
my $pid = $$;
#open log file
$| = 1; #enable auto flush
open(my $log_fh, ">>", $trace_log) or die "unable to open '$trace_log' to write: $!";
my $now_time = strftime("%F %T", localtime());
my @call_tree;
get_call_tree($pid, \@call_tree);

my $self_cmd = $0;
$self_cmd =  "$self_cmd " . (join " ", @ARGV) if @ARGV;
my $self_cwd = getcwd();

print {$log_fh} "=" x 80,"\n";
printf {$log_fh} "$now_time\n";
printf {$log_fh} "[call cmd]: %s\n", $self_cmd;
printf {$log_fh} "[call cwd]: %s\n", $self_cwd;
printf {$log_fh} "[call tree]: \n";
printf {$log_fh} "pid\tcmdline\n";
my $indent = 0;
for my $call (@call_tree){
    my ($the_pid, $cmdline) = @{$call};
    my @cmdline = map { "'$_'"} @{$cmdline};
    my $cmd= join(" ", @cmdline);
    printf {$log_fh}  ("%d\t%s%s\n", $the_pid, " " x (++$indent), $cmd);
}
print {$log_fh} "=" x 80,"\n\n";
close($log_fh);
#execute the original cmd
my $orig_cmd = "$orig_dir/" . basename($0);
exec $orig_cmd,@ARGV or die "failed to execute original cmd $orig_cmd':$!";
