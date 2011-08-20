#!/usr/bin/perl
##
#Visit website with REAL browser, use the Selenium Web Automation framework
##
use strict;
use warnings;

use POSIX;
use WWW::Selenium;
use Getopt::Long;

$| = 1; #enable autoflush

#url to fetch
my $url;
#complete the task in how many minutes
my $minutes = 4 * 60 ;
#Do this how many times
my $num = 100;
#how many days
my $days = 1;
#where Selenium Server is running
my $sel_host = "192.168.9.106";
#time precision, for efficiency,default to 20 seconds
my $precision = 20; 
GetOptions('url=s'  => \$url,
	'minutes=i' => \$minutes,
	'num=i'     => \$num,
	'days=i'     => \$days,
	'help|?'    => \&usage);

sub usage{
	print "Usage:\n";
	print "$0 --url=<url_to_access> --minutes=<access_time_range> --num=<# of times> --days=<# of days>\n";
	print "eg: \n";
	print "    $0 --url=http://www.google.com --minutes=180 --num=50 -days=5\n";
	print "    will access google.com 50 times in 3 hours,do it for 5 days\n";
	exit(1);
}
unless($url){
	usage();
}

sub time2str;
sub visit_with_firefox;

#connect to Selenium Server
my $sel = WWW::Selenium->new( host => $sel_host,
			  port => 4444,
			  browser => "*firefox",
			  browser_url => $url 
			);

BEGIN:
$sel->start;
#timeout 1 minutes
$sel->set_timeout(60*1000);
my $start_time = int(time()/$precision);
printf "Started at %s\n", time2str($start_time);
my %seen;
#get $num unique time point in $munutes
my $total_time_point = $minutes*60/$precision;
while (1) {
	my $t = int(rand($total_time_point));
	$seen{$t} = 1;
	last if keys(%seen) == $num;
}
my @check_points = sort { $a<=>$b} keys %seen;
@check_points = map { $_ + $start_time } @check_points;
print "Time to check:\n";
for my $c (@check_points){
	print time2str($c),"\n";
}
print "\n";
#check if it's time to do a task, then sleep 30 seconds, wake up and check
#again. stop when there's no more task
while(1){
	my $remain = @check_points;
	last unless $remain; #we have finished
	my $next_check = $check_points[0];
	my $now = int(time()/$precision);
	printf "now: %s\n", time2str($now);
	printf "next check: %s\n", time2str($next_check);
	if($now >= $next_check){
		print "Checking...\n";
		visit_with_firefox();
		shift @check_points;
	}
	sleep($precision/2);
}

$sel->stop();
$days--;
#do it tomorrow
print "Today's work is done, see you tomorrow\n\n";
if($days){
	sleep(86400 - $minutes * 60);
	goto BEGIN;
}
print "All done!\n";

sub visit_with_firefox{
	print "Visiting $url\n";
	eval '$sel->open($url)'; warn $@ if $@;
	print "Clearing cookies\n";
	$sel->delete_all_visible_cookies();
}

 sub time2str {
	 my $t = shift;
	 strftime('%H:%M:%S',localtime($t * $precision));
 }
