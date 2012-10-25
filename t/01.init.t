use Test::More tests => 2;

BEGIN {
    use lib './lib';
    use Wellington;
    my( $wellington ) = Wellington->new( source_keys => 't/vms_description.yaml');
    ok( defined( $wellington ) );
    ok( $wellington->isa( 'Wellington' ) );
}

#diag( "Instantiating Wellington $Wellington::VERSION" );
