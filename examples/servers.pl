#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';
use Wellington;
use Data::Dumper;
use Config::Simple;
use English '-no_match_vars';
use IPC::Open3 'open3';
{
    local $SIG{CHLD} = 'IGNORE';
}
my %config;
Config::Simple->import_from( "$ENV{'HOME'}/.wellingtonrc", \%config );
#print Data::Dumper->Dump([\%config], [qw(*config)]);
#my $yaml = `cat t/vms_description.yaml`;
my ( $writer, $reader, $err );
open3( $writer, $reader, $err, 'cat t/vms_description.yaml' );
my $yaml = do { local $INPUT_RECORD_SEPARATOR = <$reader> };
my $wellington = Wellington->new( source_keys => $yaml );
$wellington->usage unless @ARGV;
my $server = $ARGV[0];
print "Finding info for $server\n";
my $node = $wellington->find( $server, $config{'fqdn'} );
#print Dumper $node;
if ( %{ $node->puppet_facts } ) {

    for my $fact (
        qw{ fqdn virtual productname serialnumber operatingsystem operatingsystemrelease physicalprocessorcount memorysize }
      )
    {
        print "$fact: ", ${ $node->puppet_facts->{values} }{$fact}, "\n";
    }
    if ( ${ $node->puppet_facts->{values} }{'virtual'} eq 'kvm' ) {
        print "This is a KVM host. . . finding additional info. . . \n";
    }

    #print '----', "\n";
    #for my $fact (keys %{$node->puppet_facts->{values}} ) {
    #    print "$fact: ", ${ $node->puppet_facts->{values}}{$fact}, "\n";
    #}

}
print $wellington->info($server);
print $wellington->key_data($server), "\n";
