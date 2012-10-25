use Test::More tests => 1;

BEGIN {
    use lib './lib';
    use_ok( 'Wellington' );
}

diag( "Testing Wellington $Wellington::VERSION" );
