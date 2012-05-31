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

use File::Path;
use File::Spec;
use Getopt::Long;
use POSIX;

my $version = "1.1";
my($opt_h,$opt_list, $opt_separate, $opt_v, $opt_all, $opt_dir);
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
	print "  $0 -a|--all-tables [file.sql ...]\n";
	print "    split to one .sql file per table\n";
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
	print "    -o|--output-dir directory to output sql files\n";
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

sub get_true_item{
	my $hash = shift;
	for my $key (keys %{$hash}){
		return $key if $hash->{$key};
	}
	return undef;
}


sub create_file{
	my $filename = shift;
	if($opt_dir){
		mkpath($opt_dir) unless -d $opt_dir;
		$filename = File::Spec->catfile($opt_dir, $filename);
	}
	log_msg "create file '$filename'";
	open(my $handle, ">", $filename) or 
		die "unable to open '$filename' to write";
	return $handle;
}

GetOptions(
	'h|help' 	=> \$opt_h,
	'debug'		=> \$debug,
	'a|all-tables'	=> \$opt_all,
	'd|databases=s'	=> \@opt_databases,
	't|tables=s'	=> \@opt_tables,
	'l|list'	=> \$opt_list,
	'o|output-dir=s'=> \$opt_dir,
	's|separate'	=> \$opt_separate,
	'v|version'	=> \$opt_v,
	);

my $DB_RE_CAP = qr/^-- Current Database: .(\w+)./;
my $TBL_RE_CAP = qr/^-- Table structure for table .(\w+)./;

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

if($opt_h || !(@opt_databases || @opt_tables || $opt_all)){
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
	my $db_cnt = scalar @databases;
	my $end_cnt = 0;
	my $in_header = 1;
	my $dump_header = "";

	my %in_db;
	my ($cur_db,$prev_db);
	my $out_handle;
	
	for my $db (@databases){
		$in_db{$db} = 0;
	}	

	line: while(<>){
		$prev_db = get_true_item(\%in_db);

		if(eof() && $prev_db){
			log_msg "End DB [eof] '$prev_db'";
			last;
		}

		if(/$DB_RE_CAP/){
			$in_header = 0;
			$cur_db = $1;

			my $found = 0;
			if($prev_db){
				$found = 1;
				$end_cnt++;
				log_msg "End DB '$prev_db'";
				$in_db{$prev_db} = 0;
			}

			if (exists($in_db{$cur_db})){
				$found = 1;
				log_msg "Found DB '$cur_db'";
				$in_db{$cur_db} = 1;
				if($opt_separate){
					my $out_file = "$cur_db.sql";
					my $handle = create_file($out_file);
					select $handle if $handle;
					close($out_handle) if $out_handle;
					$out_handle = $handle;
				}
				print $dump_header;
			}
			log_msg "$_" if $found;
			
		}
		$dump_header .= $_ if($in_header);
	
		$prev_db = get_true_item(\%in_db);
		print if $prev_db;

		#if all requested databases extracted, we are done
		if($end_cnt == $db_cnt){
			last line;
		}
	}
	close($out_handle) if $out_handle;
	exit(0);
}

#extract selected tables
if(@opt_tables || $opt_all){
	my @tables =  split(/,/,join(',',@opt_tables));
	my $table_cnt = scalar @tables;
	my $end_cnt = 0;

	my $in_header = 1;
	my $dump_header = "";
	my (%in_db, %in_table);
	my ($cur_db, $cur_table);
	my ($prev_db, $prev_table);
	my $out_handle;

	for my $table (@tables){
		my ($db_name, $tbl_name) = split /\./, $table;
		#if it's not in db.name format
		if($tbl_name){
			$in_db{$db_name} = 0;
		}	
		$in_table{$table} = 0;
	}	

	while(<>){
		$prev_table = get_true_item(\%in_table);
		$prev_db = get_true_item(\%in_db);
		
		#end of file, just for debug purpose
		if(eof()){
			if($prev_table){
				log_msg "End Table [eof] '$prev_table'";
				print "-- End table '$prev_table'\n\n";
			}

			log_msg "End DB [eof] '$prev_db'" if $prev_db;
			last;
		}

		#locate database
		if(/$DB_RE_CAP/){
			$in_header = 0;
			$cur_db = $1;

			my $found = 0;
			if($prev_db){
				$found = 1;
				if($prev_table){
					log_msg "End Table '$prev_table'";
					print "-- End table '$prev_table'\n\n";
					$in_table{$prev_table} = 0;
					$prev_table = undef;
					$end_cnt++;
				}
				log_msg "End DB '$prev_db'";
				$in_db{$prev_db} = 0;
			}

			if (exists($in_db{$cur_db})){
				$found = 1;
				log_msg "Found DB '$cur_db'";
				$in_db{$cur_db} = 1;
			}
			log_msg "$_" if $found;
			next;
			
		}
		$dump_header .= $_ if($in_header);

		#locate table
		if($cur_db && /$TBL_RE_CAP/){
			$in_header = 0;
			$cur_table = $1;
			$cur_table = $cur_db ? "$cur_db.$cur_table" : "$cur_table";
			my $found = 0;
			if($prev_table){
				$found++;
				$end_cnt++;
				$in_table{$prev_table} = 0;
				log_msg "End Table '$prev_table'";

				#output table end
				print "-- End table '$prev_table'\n\n";
			}
			if(exists($in_table{$cur_table}) || $opt_all){
				$found++;
				$in_table{$cur_table} = 1;
				log_msg "Found table '$cur_table'";

				 if ($opt_separate || $opt_all){
					##output table start
					my $out_file = "$cur_table.sql";
					my $handle = create_file($out_file);
					select $handle if $handle;
					close($out_handle) if $out_handle;
					$out_handle = $handle;
				}
				print $dump_header;
				print $_;


			}
			log_msg "$_" if $found;
		}else{
			my $in_table = get_true_item(\%in_table);
			print if($in_table)

		}

		#if all requested databases extracted, we are done
		if(!$opt_all && ($end_cnt == $table_cnt)){
			log_msg "End DB [last tbl]'$prev_db'" if $prev_db;
			log_msg "Done";
			last;
		}
	}
	close($out_handle) if $out_handle;
}
