#!/usr/bin/perl -w

#Two way to sort IP address

my @ip = qw(192.168.100.1 192.168.1.100 192.168.1.254 8.8.8.8);
# 1st way
sub by_ip{
        pack('C4'=> (split /\./, $a))
                cmp
                pack('C4'=> (split /\./, $b));
}
my @ip_sorted = sort by_ip @ip;

print "using pack function:\n";
print join("\n", @ip_sorted),"\n\n";

# 2nd way
use Socket;
@ip_sorted = sort { inet_aton($a) cmp inet_aton($b) } @ip;

print "using inet_aton:\n";
print join("\n", @ip_sorted),"\n";