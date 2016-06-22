package Catmandu::Exporter::Stat;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Statistics::Basic;
use List::Util;
use Moo;

with 'Catmandu::Exporter';

has fields       => (is => 'rw');
has as           => (is => 'ro', default => sub { 'Table'} );
has 'values'     => (is => 'ro');
has res          => (is => 'ro');

sub add {
    my ($self, $data) = @_;

    unless (defined $self->fields) {
        $self->fields(join(",",sort keys %$data));
    }

    if ($self->values) {
        $self->value_stats($data);
    }
    else {
        $self->key_stats($data);
    }
}

sub value_stats {
    my ($self,$data) = @_;

    my @keys = split(/,/,$self->fields);

    for my $key (@keys) {
        my $cnt = 0;

        next unless exists $data->{$key};

        my $val = $data->{$key};

        if (is_array_ref($val)) {
            for (@$val) {
                if (!defined($_) || length($val) == 0) {
                    $self->{res}->{$key}->{__values__}->{'<null>'} += 1;
                }
                else {
                    $self->{res}->{$key}->{__values__}->{$_} += 1;
                }
            }
        }
        else {
            if (!defined($val) || length($val) == 0) {
                $self->{res}->{$key}->{__values__}->{'<null>'} += 1;
            }
            else {
                $self->{res}->{$key}->{__values__}->{$val} += 1;
            }
        }
    }
}

sub key_stats {
    my ($self,$data) = @_;
    my @keys = split(/,/,$self->fields);

    for my $key (@keys) {
        my $cnt = 0;
        my $val = $data->{$key};

        if (!defined($val)) {
            $cnt = 0;
            $self->{res}->{$key}->{__values__}->{'<null>'} += 1;
        }
        elsif (is_array_ref($val)) {
            $cnt = int(@$val);
            for (@$val) {
                 $self->{res}->{$key}->{__values__}->{$_} += 1;
            }
        }
        elsif (is_hash_ref($val)) {
            $cnt = 1;
            $self->{res}->{$key}->{__values__}->{$val} += 1;
        }
        elsif (length($val) == 0) {
            $cnt = 0;
            $self->{res}->{$key}->{__values__}->{'<null>'} += 1;
        }
        else {
            $cnt = 1;
            $self->{res}->{$key}->{__values__}->{$val} += 1;
        }

        push @{$self->{res}->{$key}->{__counts__}} , $cnt;
    }
}

sub commit {
    my ($self) = shift;

    my @keys = split(/,/,$self->fields);

    if ($self->values) {
        for my $key (@keys) {
            my $cnt = [];
            for my $val (keys %{$self->{res}->{$key}->{__values__}}) {
                my $c = $val eq '<null>' ? 0 : $self->{res}->{$key}->{__values__}->{$val};
                push @$cnt , $c;
            }
            $self->{res}->{$key}->{__counts__} = $cnt;
        }
    }

    my $fields;

    if ($self->values) {
        $fields = [qw(name count zeros zeros% min max mean median variance stdev uniq entropy)];
    }
    else {
        $fields = [qw(name count zeros zeros% min max mean median mode variance stdev uniq entropy)];
    }

    my $exporter = Catmandu->exporter(
                        $self->as,
                        fields => $fields,
                        file => $self->file
                   );

    for my $key (@keys) {
        my $stats = {};
        $stats->{name} = $key;

        my $val  = $self->{res}->{$key}->{__counts__};

        $stats->{count}    = defined($val) && @$val ? List::Util::sum0(@$val) : 'n/a';
        $stats->{min}      = defined($val) && @$val ? List::Util::min(@$val) : 'n/a';
        $stats->{max}      = defined($val) && @$val ? List::Util::max(@$val) : 'n/a';
        $stats->{mean}     = defined($val) && @$val ? '' . Statistics::Basic::mean($val) : 'n/a';
        $stats->{median}   = defined($val) && @$val ? '' . Statistics::Basic::median($val) : 'n/a';
        $stats->{variance} = defined($val) && @$val ? '' . Statistics::Basic::variance($val) : 'n/a';
        $stats->{stdev}    = defined($val) && @$val ? '' . Statistics::Basic::stddev($val) : 'n/a';

        unless ($self->values) {
            $stats->{mode}     = defined($val) && @$val ? '' . Statistics::Basic::mode($val) : 'n/a';
        }

        my ($zeros,$zerosp) = ('n/a','n/a');

        if (defined($val) && @$val) {
            if ($self->values) {
                $zeros  = int(grep {$_ == 0} @$val);
                $zerosp = sprintf "%.1f" , $stats->{count} > 0 ? 100 * $zeros / ($zeros + $stats->{count}) : 100;
            }
            else {
                $zeros  = int(grep {$_ == 0} @$val);
                $zerosp = sprintf "%.1f" , @$val > 0 ? 100 * $zeros / int(@$val) : 100;
            }
        }

        $stats->{zeros}    = $zeros;
        $stats->{'zeros%'} = $zerosp;

        $stats->{uniq}     = defined($val) && @$val ? $self->uniq($key) : 'n/a';

        $stats->{entropy}  = $self->entropy($key);

        $exporter->add($stats);
    }

    $exporter->commit;
}

sub uniq {
    my ($self,$key) = @_;

    return int(grep({ $_ ne '<null>' } keys %{$self->{res}->{$key}->{__values__}}));
}

sub entropy {
    my ($self,$key) = @_;

    return 'n/a' unless exists $self->{res}->{$key}->{__values__};

    my $values = $self->{res}->{$key}->{__values__};
    my $cnt = 0;

    for my $k (keys %$values) {
        $cnt += $values->{$k};
    }

    return 'n/a' unless $cnt > 0;

    my $h = 0;
    for my $k (keys %$values) {
        my $p = $values->{$k}/$cnt;
        $h += $p * log($p)/log(2);
    }

    return sprintf "%.1f/%.1f" , -1 * $h ,log($cnt)/log(2);
}

=head1 NAME

Catmandu::Exporter::Stat - a statistical export

=head1 SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu convert -v JSON to Stat --fields isbn

    # Calculate statistics on the uniqueness of ISBN numbers in the dataset
    cat data.json | catmandu convert -v JSON to Stat --fields isbn --values 1

    # Export the statistics as YAML
    cat data.json | catmandu convert -v JSON to Stat --fields isbn --values 1 --as YAML

=head1 DESCRIPTION

The L<Catmandu::Stat> package can be used to calculate statistics on the availablity of
fields in a data file. Use this exporter to count the availability of fields or count
the number of duplicate values. For each field the exporter calculates the following
statistics:

  * name    : the name of a field
  * count   : the number of non-zero occurences of a field in all records
  * zeros   : the number of records without a field
  * zeros%  : the percentage of records without a field
  * min     : the minimum number of occurences of a field in any record
  * max     : the maximum number of occurences of a field in any record
  * mean    : the mean number of occurences of a field in all records
  * median  : the median number of occurences of a field in all records
  * mode    : the most common number of occurences of a field in all records
  * variance : the variance of the field number
  * stdev   : the standard deviation of the field number
  * uniq    : the number of uniq values
  * entropy : the minimum and maximum entropy in the field values

In case of values:

  * count   : the number of non-zero values found in all records
  * zeros   : the number of values which are mull or undefined
  * zeros%  : the percentage of values which are undefined
  * min     : the minimum number of occurences of a value in all records
  * max     : the maximum number of occurences of a value in any records
  * mean    : the mean number of occurences of a value in all records
  * median  : the median number of occurences of a value in all records
  * variance : the variance of the value occurence number
  * stdev   : the standard deviation of the value occurenve number
  * uniq    : the number of uniq values
  * entropy : the minimum and maximum entropy in the field values

Details:

  * entropy is an indication in the variation of field values (are some values more unique than others)
  * entropy values displayed as : minimum/maximum entropy
  * when the minimum entropy = 0, then all the field values are equal
  * when the minimum and maximum entropy are equal, then all the field values are different

=head1 CONFIGURATION

=over 4

=item v

Verbose output. Show the processing speed.

=item fix FIX

A fix or a fix file containing one or more fixes applied to the input data before
the statistics are calculated.

=item fields KEY[,KEY,...]

One or more fields in the data for which statistics need to be calculated. No deep nested
fields are allowed. The exporter will collect statistics on the availability of a field in
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
    cat data.json | catmandu convert JSON to Stat --fields title

    # Calculate statistics on the number of records that contain a 'title', 'isbn' or 'subject' fields
    cat data.json | catmandu convert JSON to Stat --fields title,isbn,subject

    # The next example will not work: no deeply nested fields allowed
    cat data.json | catmandu convert JSON to Stat --fields foo.bar.x.y

When no fields parameter is available, then all fields are read from the first input record.

=item values 0 | 1

When the value option is activated, then the statistics are calculated on the contents of the
fields instead of the availability of fields. Use this option to calculate statistics on
duplicate field values. For instance in the follow example, the title field has 2 duplicates,
the author field has zero duplicates. The year field is available in 2 out of 3 records, but in only
one record (33%) it contains a value.

    ---
    title: ABC
    author:
        - Test
        - Test2
    ---
    title: ABC
    author:
        - Test3
    year: ''
    ---
    title: DEF
    year: 1980

Examples of operation:

    # Calculate statistics on the uniqueness of ISBN numbers in the dataset
    cat data.json | catmandu convert JSON to Stat --fields isbn --values 1

=item as Table | CSV | YAML | JSON | ...

By default the statistics are exported in a CSV format. The use 'as' option to change the
export format.

=back

=head1 SEE ALSO

L<Catmandu::Exporter> , L<Statistics::Basic>

=cut

1;
