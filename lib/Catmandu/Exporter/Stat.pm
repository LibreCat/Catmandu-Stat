package Catmandu::Exporter::Stat;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Statistics::Basic;
use List::Util;
use Moo;

with 'Catmandu::Exporter';

has keys     => (is => 'ro' , required => 1);
has as       => (is => 'ro' , default => sub { 'CSV'} );
has 'values' => (is => 'ro');
has res      => (is => 'ro');

sub add {
    my ($self, $data) = @_;
    
    if ($self->values) {
        $self->value_stats($data);
    }
    else {  
        $self->key_stats($data);
    }
}

sub value_stats {
    my ($self,$data) = @_;

    my @keys = split(/,/,$self->keys);
    
    for my $key (@keys) {
        my $cnt = 0;
        my $val = $data->{$key} // '';

        if (is_array_ref($val)) {
            for (@$val) {
                $self->{res}->{$key}->{$_} += 1;
            }
        }
        else {
            $self->{res}->{$key}->{$val} += 1;
        }
    }
}

sub key_stats {
    my ($self,$data) = @_;
    my @keys = split(/,/,$self->keys);
    
    for my $key (@keys) {
        my $cnt = 0;
        my $val = $data->{$key};

        if (!$val) {
            $cnt = 0;
        }
        elsif (is_array_ref($val)) {
            $cnt = int(@$val);
        }
        else {
            $cnt = 1;
        }

        push @{$self->{res}->{$key}} , $cnt;
    }
}

sub commit {
    my ($self) = shift;

    my @keys = split(/,/,$self->keys);

    if ($self->values) {
        for my $key (@keys) {
            my $cnt = [];
            for my $val (keys %{$self->{res}->{$key}}) {
                my $c = $self->{res}->{$key}->{$val} // 0;
                push @$cnt , $c;
            }
            $self->{res}->{$key} = $cnt;
        }
    } 

    my $exporter = Catmandu->exporter($self->as, file => $self->file);

    for my $key (@keys) {
        my $stats = {};
        $stats->{_id} = $key;

        my $val  = $self->{res}->{$key};

        $stats->{count}    = defined($val) ? List::Util::sum0(@$val) : 0;
        $stats->{min}      = defined($val) ? List::Util::min(@$val) : 'null';
        $stats->{max}      = defined($val) ? List::Util::max(@$val) : 'null';
        $stats->{mean}     = defined($val) ? '' . Statistics::Basic::mean($val) : 'null';
        $stats->{median}   = defined($val) ? '' . Statistics::Basic::median($val) : 'null';
        $stats->{variance} = defined($val) ? '' . Statistics::Basic::variance($val) : 'null';
        $stats->{stdev}    = defined($val) ? '' . Statistics::Basic::stddev($val) : 'null';

        $exporter->add($stats);
    }

    $exporter->commit;
}

=head1 NAME

Catmandu::Exporter::Stat - a statistical export

=head1 SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu convert JSON to Stat --keys isbn

    # Calculate statistics on the uniqueness of ISBN numbers in the dataset
    cat data.json | catmandu convert JSON to Stat --keys isbn --values 1

    # Export the statistics as YAML
    cat data.json | catmandu convert JSON to Stat --keys isbn --values 1 --as YAML

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

1;
