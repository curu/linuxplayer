#!/usr/bin/perl
# By Curu Wong
# Test use of libcurl/WWW:Curl
use warnings;
use strict;

use WWW::Curl::Easy;

my $url = 'http://search.cpan.org/CPAN/authors/id/L/LO/LORN/LWP-Curl-0.09.tar.gz';
my $filename = $1 if $url =~ /([^\/]+)$/;
my $resp_body;

#Get file length via HTTP HEAD  request 
my $length;
my $curl = WWW::Curl::Easy->new();
$curl->setopt(CURLOPT_URL, $url);
#follow redirect
$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
#inlcude header in response
$curl->setopt(CURLOPT_HEADER, 1);
#do not include body in response
$curl->setopt(CURLOPT_NOBODY, 1);
$curl->setopt(CURLOPT_WRITEDATA,\$resp_body);
my $retcode = $curl->perform();
if($retcode == 0){
	print "header:$resp_body\n";
	print "*" x 80,"\n";
	$length = $curl->getinfo(CURLINFO_CONTENT_LENGTH_DOWNLOAD);
	if($length == -1 ){
		print "content length not available\n";
	}
	else {
		print "length: $length\n";
	}
}else{
	print "error happened:$retcode " . $curl->strerror($retcode) ." | "
		. $curl->errbuf ."\n";
	exit 1;
}

#if content length is larger than local, resume download
my $local_size = -s $filename;
if($local_size < $length){
	print "resume download from: $local_size\n";
	open(my $f, ">>", $filename) or die "unable to open $filename : $1";
	$curl->setopt(CURLOPT_HEADER, 0);
	$curl->setopt(CURLOPT_NOBODY, 0);
	$curl->setopt(CURLOPT_RESUME_FROM, $local_size);
	$curl->setopt(CURLOPT_WRITEDATA,$f);
	$retcode = $curl->perform();
	if($retcode == 0){
		print "Transfer OK\n";
		my $resp_code = $curl->getinfo(CURLINFO_HTTP_CODE);
		print $resp_code,"\n";
	}else{
		print "error happened:$retcode" . $curl->strerror($retcode) ." "
			. $curl->errbuf ."\n";
	}
	close($f);
}
else {
	print "no need to download\n";
}

