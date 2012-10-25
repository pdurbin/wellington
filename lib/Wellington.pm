package Wellington;
# ABSTRACT: truth-teller
use Moose;
use Wellington::Node;
use YAML::Any;
use JSON;
use RPC::XML::Client;
use IPC::Open3 'open3';
use IO::File;
use Symbol qw(gensym);
use English '-no_match_vars';
# FIXME: what does this do? from perlcritic
{
    local $SIG{CHLD} = 'IGNORE';
}
use Data::Dumper;
has source_keys => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

sub info {
    my ( $self, $key, $is_virtual ) = @_;
    #return $servers{$key};
    return $self->_lookup( $key, $is_virtual );
}

sub key_data {
    my ( $self, $key ) = @_;
    my $hashref = YAML::Any::Load( $self->source_keys );
    my $returnstring;
    while ( my ( $innerkey, $value ) = each %{ $hashref->{$key} } ) {
        $returnstring .= "$innerkey: $value\n" if $value;
    }
    return $returnstring;
}

sub cobbler {
    my ( $self, $key, $domain ) = @_;
    my $cli = RPC::XML::Client->new('http://cobbler/cobbler_api');
    my $resp = $cli->simple_request( 'get_system', $key );
    my $returnstring;
    if ( $resp ne qw{~} ) {
        $returnstring .= 'MAC address from cobbler: '
          . $resp->{'interfaces'}{'eth0'}{'mac_address'};
    }
    return $returnstring;

}

sub find {
    my ( $self, $key, $domain ) = @_;
    $domain = $domain || 'localdomain';
    my ( $writer, $reader, $err );
    open3( $writer, $reader, $err,
"curl -s -k -H 'Accept: yaml' https://puppet:8140/production/facts/$key.$domain| tail -n +2"
    );
    my $puppet_facts_yaml = do { local $INPUT_RECORD_SEPARATOR = <$reader> };
    my $puppet_facts = YAML::Any::Load($puppet_facts_yaml);
    if ( !$puppet_facts ) {
        $puppet_facts = {};
    }

    open3( $writer, $reader, $err,
"curl -s http://foreman/hosts/$key.$domain/facts?format=json"
    );
    my $foreman_facts_json = do { local $INPUT_RECORD_SEPARATOR = <$reader> };
    my $foreman_facts_with_hostname = from_json($foreman_facts_json);
    my $foreman_facts = $foreman_facts_with_hostname->{"$key.$domain"};  # works

    if ( !$foreman_facts ) {
        $foreman_facts = {};
    }

    my $node = Wellington::Node->new(
        puppet_facts  => $puppet_facts,
        foreman_facts => $foreman_facts,
    );
    return $node;
}

sub usage {
    # FIXME: DRY!
    #my $vms_desc = YAML::Any::LoadFile('t/vms_description.yaml');
    my ($self) = @_;
    my $vms_desc = _load_descriptions($self);
    print 'Try using one of these servers as an argument: ';
    for my $server ( sort keys %{$vms_desc} ) {
        print "$server ";
    }
    print "\n";
    exit 1;
}

sub _load_descriptions {
    my ($self) = @_;
    my $vms_desc = YAML::Any::Load( $self->source_keys );
    #print Dumper($vms_desc);
    return $vms_desc;
}

sub _lookup {
    my ( $self, $key, $is_virtual ) = @_;

    # load datasource: description of VMs
    my $vms_desc = _load_descriptions($self);
    #print Dumper($vms_desc);

    my $return_string = '';

    if ($is_virtual) {
        print "Please wait... determining where VM was seen running last...\n";
# http://learn.perl.org/faq/perlfaq8.html#How-can-I-capture-STDERR-from-an-external-command-
# http://stackoverflow.com/questions/777543/how-can-i-read-the-error-output-of-external-commands-in-perl
        *CATCHERR = IO::File->new_tmpfile;
        my $pid = open3( gensym, \*CATCHOUT, '>&CATCHERR', 'vms-running.pl' );
        waitpid $pid, 0;
        seek CATCHERR, 0, 0;
        if ( my $vms_running_err = <CATCHERR> ) {
            return $vms_running_err;
        }
        else {

            my $yaml = do { local $INPUT_RECORD_SEPARATOR = <CATCHOUT> };
            my $vms_running = YAML::Any::Load($yaml);
            my %vms_by_host;

            for my $physical ( keys %{$vms_running} ) {
                for my $vm ( @{ ${$vms_running}{$physical} } ) {
                    $vms_by_host{$vm} = $physical;
                }
            }

            $return_string .= 'This VM last seen running on ';
            $return_string .=
              $vms_by_host{$key} ? $vms_by_host{$key} : 'UNKNOWN';
            $return_string .= "\n";
        }
        return $return_string;
    }

}

1;
