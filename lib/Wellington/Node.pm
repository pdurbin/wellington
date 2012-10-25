package Wellington::Node;
use Moose;

has puppet_facts => (
    #is => 'rw',
    is       => 'ro',
    isa      => 'HashRef',
    required => 0,
);

has foreman_facts => (
    #is => 'rw',
    is       => 'ro',
    isa      => 'HashRef',
    required => 0,
);

1;
