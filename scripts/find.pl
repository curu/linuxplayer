#!/usr/bin/perl
################################################
#find.pl: very simple find script that support
#find files modified N seconds ago
#
#Author: Curu Wong
#Date:   2012-11-07
################################################
use strict;
use warnings;

use File::Find;
use Getopt::Long;
use File::stat;

my($opt_msec, $opt_iname, $opt_name, $opt_type);
our $name_pattern;
sub usage{
    print qq(Usage:
    $0 [options] Directory ...
    
Options:
    --msec +|-N         modified less(-) or more(+) than N seconds
    --name PATTERN      name match PATTERN(case sensitive)   
    --iname PATTERN     name match PATTERN(case insensitive)
    --type f|d          type is d(directory) or f(file)
);
}


sub wanted{
    #check file type
    if($opt_type){
        return if ($opt_type eq "f" && (! -f $File::Find::name));
        return if ($opt_type eq "d" && (! -d $File::Find::name));
    }
    #check file name
    if($name_pattern){
        return unless /$name_pattern/;
    }
    #check msec
    if($opt_msec){
        my $stat = stat($File::Find::name) 
			or print STDERR "failed to stat $File::Find::name :$!";
		my $now = time();
		if($opt_msec < 0 ){
			return unless $now - $stat->mtime < abs($opt_msec);
		}else{
			return unless ($now - $stat->mtime) >= $opt_msec
		}
    }
    print $File::Find::name,"\n";
    
}
GetOptions(
        'h|help'    =>  sub { usage; exit(0)},
        'name=s'    => \$opt_name,
        'iname=s'   => \$opt_iname,
        'msec=i'    => \$opt_msec,
        'type=s'    => \$opt_type,   
        );
#check options
if($opt_name && $opt_iname){
    print STDERR "--iname and --name can't be used together\n";
    exit(1);
}
if($opt_type && ($opt_type ne "f" and $opt_type ne "d")){
    print STDERR "unsupported type '$opt_type'\n";
    exit(1);    
}
if($opt_name){
    $name_pattern = qr/$opt_name/;
}
elsif($opt_iname){
    $name_pattern = qr/$opt_iname/;
}
if(!@ARGV){
    push @ARGV, ".";
}

find({wanted => \&wanted, no_chdir => 1}, @ARGV );
