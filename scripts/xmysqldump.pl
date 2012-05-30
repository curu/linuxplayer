#!/usr/bin/perl
########################################################################
# mysqldump extractor: 
# extract specified databases or tables from mysqldump file(sql format)
# Author: Curu Wong
# Date: 2012-06-01
# License: GPL v2
########################################################################
use strict;
use warnings;

use Getopt::Long;
use List::Util qw(sum);
use POSIX;

my $version = "1.0";
my($opt_h,$opt_list, $opt_separate, $opt_v);
my(@opt_databases, @opt_tables);
our $debug = 0;

sub usage {
	print "Usage:\n";
	print "  $0 -h|--help\n";
	print "    This page\n";
	print "\n";
	print "  $0 -l|--list [file.sql ...]\n";
	print "    List databases and tables\n";
	print "\n";
	print "  $0 [-s|--separate] -d|--databases db1,dbn... [file.sql ...]\n";
	print "    Extract selected databases:\n";
	print "\n";
	print "  $0 [-s|--separate] -t|--tables tbl1,... [file.sql ...]\n";
	print "    Extract selected tables(the first table name match):\n";
	print "\n";
	print "  $0 [-s|--separate] -t|--tables db1.tbl1,db2.tbln,... [file.sql ...]\n";
	print "    Extract selected tables(full qualified):\n";
	print "\n";
	print "Options:\n";
	print "    --debug print some debug information to STDERR\n";
	print "    -s|--separate output separate sql files named like DB.TBL.sql\n";
	print "    -v|--version show program version\n";
	print "NOTE: \n";
	print "  This program requires running myqldump with --comments option(eanbled by default)\n";
	print "  If no source sql file specified, it will read from stdin\n";
}

sub log_msg {
    my $now=strftime('%F %T',localtime());
    print STDERR "[$now]: @_\n" if $debug;
}


GetOptions(
	'h|help' 	=> \$opt_h,
	'debug'		=> \$debug,
	'd|databases=s'	=> \@opt_databases,
	't|tables=s'	=> \@opt_tables,
	'l|list'	=> \$opt_list,
	's|separate'	=> \$opt_separate,
	'v|version'	=> \$opt_v,
	);

my $CHARSET_RE = qr{\Q/*!40101 SET NAMES\E};
my $DB_RE = qr/^-- Current Database: .\w+./;
my $DB_RE_CAP = qr/^-- Current Database: .(\w+)./;
my $TBL_RE = qr/^-- Table structure for table .\w+./;
my $TBL_RE_CAP = qr/^-- Table structure for table .(\w+)./;
my $DB_RE_END = qr/^-- Current Database:/;
my $TBL_RE_END = qr/^-- Table structure for/;

#check option
if($opt_v){
	print "xmysqldump.pl v$version, by Curu Wong\n";
	print "extract datatases/tables from mysqldump\n";
	exit(0);
}
	
#list all databases and tables
if($opt_list){
	while(my $line = <>){
		if ($line =~ $DB_RE_CAP){
			print "$1\n";
			next;
		
		}
		if ($line =~ $TBL_RE_CAP) {
			print "\t$1\n";
		}
	}
	exit(0)
}

if($opt_h || !(@opt_databases || @opt_tables)){
	usage();
	exit(0);
}
if(@opt_databases && @opt_tables){
	print STDERR "Sorry, but you can't extract database and tables at the same time\n";
	exit(1)
}

#extract selected databases
if(@opt_databases){
	my @databases =  split(/,/,join(',',@opt_databases));
	my @db_re;
	my $db_cnt = scalar @databases;
	my $end_cnt = 0;
	my $got_charset = "";

	for my $db (@databases){
		my $re = qr/^-- Current Database: .\Q$db\E./;
		my $handle;
		if($opt_separate){
			my $out_file = "$db.sql";
			open($handle, ">", $out_file) or die "unable to open '$out_file' for write";
		}
		push @db_re, { db => $db, re => $re, start => 0, 'end' => 0, 'handle' => $handle };
	}	

	line: while(<>){
		#get charset comment
		$got_charset = $_ if(!$got_charset && /$CHARSET_RE/);

		for my $d (@db_re){
			my $re = $d->{'re'};
			if(!$d->{'start'} && /$re/){
				$d->{'start'} = 1;
				log_msg "find db " . $d->{'db'};
				log_msg $_;
				select $d->{'handle'} if $d->{'handle'};
				print $got_charset;
				next;
			}
			if($d->{'start'} && !$d->{'end'} && (/$DB_RE_END/ || eof())){
				$d->{'end'} = 1;
				log_msg "end db " . $d->{'db'};
				log_msg $_;
				$end_cnt++;
				next;
			}
			#output mathed lines
			if($d->{'start'} && !$d->{'end'}){
				print;
				next line;
			}
		}
		#if all requested databases extracted, we are done
		if($end_cnt == $db_cnt){
			last line;
		}
	}
	for my $d (@db_re){
		close($d->{'handle'}) if $d->{'handle'};
	}
	exit(0);
}
#extract selected tables
if(@opt_tables){
	my @tables =  split(/,/,join(',',@opt_tables));
	my @table_re;
	my $table_cnt = scalar @tables;
	my $end_cnt = 0;
	my %db_start;
	my %db_end;
	my $got_charset = "";

	for my $table (@tables){
		my ($db_name, $tbl_name) = split /\./, $table;
		#if it's not in db.name format
		if(!$tbl_name){
			$tbl_name = $db_name;
			$db_name = "";
		}
		my $re = qr/^-- Table structure for table .\Q$tbl_name\E./;
		my $re2 = $db_name ? qr/^-- Current Database: .\Q$db_name\E./ : undef;
		my $handle;
		#add to db hash
		$db_start{$db_name} = 0 if $db_name;
		if($opt_separate){
			my $out_file = $db_name ? "$db_name.$tbl_name.sql" : "$tbl_name.sql";
			open($handle, ">", $out_file) or die "unable to open '$out_file' for write";
		}
		push @table_re, { db => $db_name, dbre => $re2,
			db_start => 0, db_end => 0, 
			table => $tbl_name, re => $re, 
			start => 0, 'end' => 0 ,
			'handle' => $handle};
	}	

	line: while(<>){
		#get charset comment
		$got_charset = $_ if(!$got_charset && /$CHARSET_RE/);
		for my $d (@table_re){
			my $re = $d->{'re'};
			my $dbre = $d->{'dbre'};
			my $db = $d->{'db'};
			#log_msg $d->{'table'};
			#position target db
			if($db){
				if(!$db_start{$db} && /$dbre/){
					$db_start{$db} = 1;
					log_msg "find db " . $db;
					log_msg $_;
					next line;
				}
				if($db_start{$db} && !$db_end{$db} && (/$DB_RE_END/ || eof())){
					log_msg "end db " . $db;
					log_msg $_;
					$db_end{$db} = 1;
					next;
				}
				#skip if we are not in the right database
				next if !$db_start{$db} || $db_end{$db};
			}
			if(!$d->{'start'} && /$re/){
				log_msg "find table " . $d->{'table'};
				log_msg $_;
				$d->{'start'} = 1;
				select $d->{'handle'} if $d->{'handle'};
				print $got_charset;
				printf 'USE DATABASE `%s`;'."\n", $d->{'db'} if $d->{'db'};
				next;
			}
			if($d->{'start'} && !$d->{'end'} && (/$TBL_RE_END/ || /$DB_RE_END/ || eof())){
				$d->{'end'} = 1;
				log_msg "end table " . $d->{'table'};
				log_msg $_;
				$end_cnt++;
				next;
			}
			if($d->{'start'} && !$d->{'end'}){
				print;
				next line;
			}
		}
		#if all requested databases extracted, we are done
		if($end_cnt == $table_cnt){
			last line;
		}
	}
	for my $d (@table_re){
		close($d->{'handle'}) if $d->{'handle'};
	}
	exit(0);
}
