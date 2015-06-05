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
        my $val = is_value($data->{$key}) ? $data->{$key} : '<null>';

warn $val;

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

        if (!defined($val)) {
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
                my $c = $val eq '<null>' ? 0 : $self->{res}->{$key}->{$val};
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

        my ($zeros,$zerosp) = ('null','null');

        if (defined($val)) {
            $zeros  = int(grep {$_ == 0} @$val);
            $zerosp = @$val > 0 ? 100 * $zeros / int(@$val) : 0;
        }

        $stats->{zeros}    = $zeros;
        $stats->{'zeros%'} = $zerosp;

        $exporter->add($stats);
    }

    $exporter->commit;
}

=head1 NAME

Catmandu::Exporter::Stat - a statistical export

=head1 SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu convert -v JSON to Stat --keys isbn

    # Calculate statistics on the uniqueness of ISBN numbers in the dataset
    cat data.json | catmandu convert -v JSON to Stat --keys isbn --values 1

    # Export the statistics as YAML
    cat data.json | catmandu convert -v JSON to Stat --keys isbn --values 1 --as YAML

=head1 DESCRIPTION

The L<Catmandu::Stat> package can be used to calculate statistics on the availablity of
fields (keys) in a data file. Use this exporter to count the availability of fields or
the number of duplicate values. For each field the exporter calculates the following
statistics:

  * count  : the number of occurences of a field in all records
  * min    : the minimum number of occurences of a field in any record
  * max    : the maximum number of occurences of a field in any record
  * mean   : the mean number of occurences of a field in all records
  * median : the median number of occurences of a field in all records
  * variance : the variance of the field number
  * stdev  : the standard deviation of the field number
  * zeros  : the number of records without a field
  * zeros% : the percentage of records without a field

In case of values:

  * count  : the number of occurences of a value in all records
  * min    : the minimum number of occurences of a value in all records
  * max    : the maximum number of occurences of a value in any records
  * mean   : the mean number of occurences of a value in all records
  * median : the median number of occurences of a value in all records
  * variance : the variance of the value occurence number
  * stdev  : the standard deviation of the value occurenve number
  * zeros  : the number of values which are undefined
  * zeros% : the percentage of values which are undefined

=head1 CONFIGURATION

=over 4

=item v 

Verbose output. Show the processing speed.

=item fix FIX

A fix or a fix file containing one or more fixes applied to the input data before 
the statistics are calculated.

=item keys KEY[,KEY,...]

One or more keys in the data for which statistics need to be calculated. No deep nested
keys are allowed. The exporter will collect statistics on the availability of a field in 
all records. For instance, the following record contains one 'title' field, zero 'isbn'
fields and 3 'author' fields

    ---
    title: ABCDEF
    author: 
        - Davis, Miles
        - Parker, Charly
        - Mingus, Charles
    year: 1950

Examples of operation:

    # Calculate statistics on the number of records that contain a 'title' 
    cat data.json | catmandu convert JSON to Stat --keys title

    # Calculate statistics on the number of records that contain a 'title', 'isbn' or 'subject' fields 
    cat data.json | catmandu convert JSON to Stat --keys title,isbn,subject

    # The next example will not work: no deeply nested keys allowed
    cat data.json | catmandu convert JSON to Stat --keys foo.bar.x.y

=item values 0 | 1

When the value option is activated, then the statistics are calculated on the contents of the
fields instead of the availability of fields. Use this option to calculate statistics on 
duplicate field values. For instance in the follow example, the title field has 2 duplicates,
the author field has zero duplicates.

    ---
    title: ABC
    author: 
        - Test
        - Test2
    ---
    title: ABC
    author:
        - Test3
    ---
    title: DEF

Examples of operation:

    # Calculate statistics on the uniqueness of ISBN numbers in the dataset
    cat data.json | catmandu convert JSON to Stat --keys isbn --values 1

=item as CSV | YAML | JSON | ...

By default the statistics are exported in a CSV format. The use 'as' option to change the
export format.

=back

=head1 SEE ALSO

L<Catmandu::Exporter> , L<Statistics::Basic>

=cut

1;
