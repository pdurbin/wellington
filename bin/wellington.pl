#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Wellington;
use Data::Dumper;
use Config::Simple;
use English '-no_match_vars';
use Socket;
use Carp;
use IPC::Open3 'open3';
{
    local $SIG{CHLD} = 'IGNORE';
}
my %config;
my @facts =
  qw{ fqdn virtual productname serialnumber operatingsystem operatingsystemrelease physicalprocessorcount memorysize };
Config::Simple->import_from( "$ENV{'HOME'}/.wellingtonrc", \%config );
#print Data::Dumper->Dump([\%config], [qw(*config)]);

my ( $writer, $reader, $err );
open3( $writer, $reader, $err, 'csv2yaml.pl ~/docs/virt/kvm/vms.csv' );
my $yaml = do { local $INPUT_RECORD_SEPARATOR = <$reader> };
#my @errors = <$err>;     #Errors here, instead of the console
my $wellington = Wellington->new( source_keys => $yaml );
$wellington->usage unless @ARGV;
my $server = $ARGV[0];
print "Finding info for $server\n";
my $address1 = inet_aton($server);
if ($address1) {
    my $address2 = inet_ntoa($address1);
    my $from_reverse = gethostbyaddr( inet_aton($address2), AF_INET );
    print "$address2 ($from_reverse) found in DNS\n";
}
else {
    carp "Couldn't find '$server' in DNS";
}
print "Probable OBM: https://$server$config{'obm-append'}.$config{'fqdn'}\n";
my $node = $wellington->find( $server, $config{'fqdn'} );
#print Dumper $node;
my $is_virtual = 0;
print_facts();
my $localdata = $wellington->key_data($server);
print "$localdata" if $localdata;
my $cobbler_info = $wellington->cobbler( $server, $config{'fqdn'} );
print "$cobbler_info\n" if $cobbler_info;
print $wellington->info( $server, $is_virtual );

sub print_facts {

    if ( %{ $node->puppet_facts } ) {

        for my $fact (@facts) {
            print "$fact: ", ${ $node->puppet_facts->{values} }{$fact}, "\n";
        }
        if ( ${ $node->puppet_facts->{values} }{'virtual'} eq 'kvm' ) {
            $is_virtual = 1;
        }

    }
    elsif ( %{ $node->foreman_facts } ) {

        for my $fact (@facts) {
            #print "$fact: ", ${ $node->foreman_facts->{values} }{$fact}, "\n";
            print "$fact: ", ${ $node->foreman_facts }{$fact}, "\n";
        }
        if ( ${ $node->foreman_facts }{'virtual'} eq 'kvm' ) {
            $is_virtual = 1;
        }
    }
    return;
}
