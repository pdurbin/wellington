use Test::More tests => 1;

my $test1 = 'Usage test'; 

BEGIN {
    use lib './lib';
    use Wellington;
    #my $vms_description = `cat t/vms_description.yaml`;
    #print $vms_description, "\n";
    #my( $wellington ) = Wellington->new( source_keys => $vms_description);
    #ok( defined( $wellington ) );
    my $got = `examples/servers.pl`;
    # FIXME: trailing space
    my $expected = "Try using one of these servers as an argument: db1 fs1 mx1 \n";
    is ($got, $expected, $test1);
}

#diag( "$test1" );
