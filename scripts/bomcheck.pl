#!/usr/bin/perl
########################################################################
#bomcheck.pl: check file for UTF-8 Byte-Order-Mark, optionally remove it
#Author: Curu Wong
#Date:   2012-06-07
#License: GPL v2
########################################################################
use File::Find;

use Getopt::Long;

my ($opt_fix, $opt_include);
my $BOM = "\xEF\xBB\xBF";
our $file_re;

sub usage{
print <<EOF;
Usage: $0 [OPTIONS] PATH ...
Check files at PATH for UTF8 Byte-Order-Mark 
Optionally remove it if --fix option supplied.

Options:
    -f|--fix              Remove BOM mark if found
    -i|--include=PATTERN  regex PATTERN to match file name(case insensitive)
EOF
}

sub checkbom{
	my $filename = shift;
	my $fix = shift;
	my ($mark,$content);
	open(my $fh, "<", $filename) 
		or warn "unable to open '$filename': $!" and return;
	
	sysread($fh, $mark, 3) 
		or warn "unable to read '$filename': $!" and return;

	if($mark eq $BOM){
		print "Found BOM in '$filename'\n";
		if($fix){
			my $buf;
			$content = "";
			while(my $nread = sysread($fh, $buf, 1024)){
				$content .= $buf;
			}
			close($fh);
			open(my $fh, ">", $filename) 
				or warn "unable to open '$filename' to write $!";
			print {$fh} $content;
			print "Removed BOM from '$filename'\n";
		}
		close($fh);
		return 1;
	}
	else{
		close($fh);
		return 0;
	}
}

sub wanted {
	return if -d $File::Find::name;
	if($opt_include && !/$file_re/){
		return	
	}
	checkbom($File::Find::name, $opt_fix);
}

GetOptions(
	'h|help' => sub { usage(); exit(0) },
	'f|fix'  => \$opt_fix,
	'i|include=s'  => \$opt_include,
	) or usage() && exit(1);

my @path;
for my $p (@ARGV){
	if(! -e $p){
		print STDERR "WARN: '$p' does not exist\n";
	}
	else{
		push @path, $p;
	}
}
if(!@path){
	usage();
	exit(1);
}
if($opt_include){
	$file_re = qr/$opt_include/i;
}
find({wanted=>\&wanted, no_chdir => 1}, @path);
