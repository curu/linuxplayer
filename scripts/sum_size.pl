#!/usr/bin/perl
#########################################################################
##sum_size.pl: caculate the total size of the files/directories from STDIN
##             or command line 
##usage: find /data -iname '*.tmp' | sum_size.pl
##       sum_size.pl /usr/share/man*
##Author: Curu Wong
##Date:   2012-01-06
##License: GPL v2
#########################################################################
use File::Find;

sub beauty_size{
	my $size = shift;
	my $k = 2**10;
	my $m = 2**20;
	my $g = 2**30;
	my $r;
	if($size >= $g ){
		$r = sprintf "%.2fG", $size /$g;
	}elsif($size >= $m){
		$r = sprintf "%.2fM", $size /$m;
	}elsif($size >= $k){
		$r = sprintf "%.2fK", $size /$k;
	}else{
		$r = $size;
	}
	return $r;
}

sub sum_dir{
	my $dir = shift;
	my $total;
	my %options = (no_chdir => 1 ,
	       		wanted   => sub { $total += ( -s $_ )}
		);
	find(\%options, $dir);
	return $total;
}

my $total = 0;

if(@ARGV){
	for my $file (@ARGV){
		next unless -e $file;
		if(-d $file){
			$total += sum_dir($file);
		}else{
			my $size = -s $file;
			$total += $size;
		}
	}
}
else{
	while(my $file = <>){
		chomp $file;
		next unless -e $file;
		my $size = -s $file;
		$total += $size;
	}
}
printf "size total: %s\n",beauty_size($total);


