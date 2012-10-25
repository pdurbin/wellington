use Test::More tests => 1;

my $test1 = 'Info test'; 

BEGIN {
    use lib './lib';
    use Wellington;
    #use IPC::Open3 'open3';
    #$SIG{CHLD} = 'IGNORE';
    my $vms_description = `cat t/vms_description.yaml`;
    print $vms_description, "\n";
    my( $wellington ) = Wellington->new( source_keys => $vms_description);
    my $got = `examples/servers.pl mx1`;
    print $got;
    #open3($writer, $reader, $err, 'examples/servers.pl mx1');
    #my $got = <$reader>;
    my $expected = 'Finding info for mx1
';
    #SKIP: {
    #skip('skipping', 1);
    is ($got, $expected, $test1);
    #}
}

#diag( "$test1" );
