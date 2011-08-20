#!/usr/bin/perl
###############################################
# fail2ban-stat.pl Display fail2ban statistics 
# by Curu Wong http://www.linuxplayer.org
###############################################
use strict;
use warnings;

my $ban_logfile = "/var/log/fail2ban.log";
open(my $LOG_FILE, "<", $ban_logfile) or die "Failed to open file '$ban_logfile' : $!";
my %ban = ();
while(my $line = <$LOG_FILE>){
	next unless $line =~ /\bBan\b/;
	chomp($line);
	my @fields = split /\s+/, $line;
	my $date = $fields[0];
	my $time = (split /,/,$fields[1])[0];
	(my $filter = $fields[4]) =~ s/^\[|\]$//g;
	my $service = (split /-/, $filter)[0];
	my $ip = $fields[$#fields];
	$ban{$date}{$service} = [] unless defined($ban{$date}{$service});
	push(@{$ban{$date}->{$service}},$ip);
}

close($LOG_FILE);
my $indent = " " x 4;
for my $date (sort keys %ban){
	my @services = sort keys %{$ban{$date}};
	print "$date\n";
	for my $s (@services){
		my @ip = @{$ban{$date}->{$s}};
		print $indent;
		printf "%s: %d IP banned\n", $s, scalar @ip;
		for my $ip (@ip){
			print $indent x 2;
			print "$ip\n";
		}
	}
}
