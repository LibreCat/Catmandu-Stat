package Catmandu::Exporter::Stat;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Statistics::Basic;
use List::Util;
use Algorithm::HyperLogLog;
use Statistics::TopK;
use POSIX qw(floor);
use Moo;

with 'Catmandu::Exporter';

has fields       => (is => 'rw');
has as           => (is => 'ro', default => sub { 'Table'} );
has res          => (is => 'ro');
has topk         => (is => 'ro', default => sub { 100 });
has hll          => (is => 'ro', default => sub { 14 });

sub add {
    my ($self, $data) = @_;

    unless (defined $self->fields) {
        $self->fields(join(",",sort keys %$data));
    }

    my @keys = split(/,/,$self->fields);

    for my $key (@keys) {
        my $val = $data->{$key};
        $self->inc_key_value($key,$val);
    }
}

# Update a counter of unique values in a field , plus the number of
# values in a field.
sub inc_key_value {
    my ($self,$key,$val) = @_;

    my $prev  = $self->{res}->{$key};
    my $count = 0;

    $prev->{hll} = Algorithm::HyperLogLog->new($self->hll) 
                            unless exists $prev->{hll};
    $prev->{top} = Statistics::TopK->new($self->topk) 
                            unless exists $prev->{top};

    if (is_array_ref($val)) {
        for (@$val) {
            if (!defined($_) || length($_) == 0) {
                $prev->{top}->add('<null>');
                $prev->{hll}->add('<null>');
            }
            else {
                $prev->{top}->add($_);
                $prev->{hll}->add($_);
                $count++;
            }
        }
    }
    elsif (is_hash_ref($val)) {
        # Nested fields are not supported for now. Treat them as unique
        # values...
        $prev->{top}->add("$val");
        $prev->{hll}->add("$val");
        $count++;
    }
    else {
        if (!defined($val) || length($val) == 0) {
            $prev->{top}->add('<null>');
            $prev->{hll}->add('<null>');
        }
        else {
            $prev->{top}->add($val);
            $prev->{hll}->add($val);
            $count++;
        }
    }

    push @{$prev->{__counts__}} , $count;

    $self->{res}->{$key} = $prev;
}

# Return an array of number of times a field is available in a record
sub get_key_counts {
    my ($self,$key) = @_;
    return [] unless $self->{res}->{$key};
    return $self->{res}->{$key}->{__counts__};
}

# Return the estimated number of unique values in a field
sub get_key_uniq {
    my ($self,$key) = @_;
    return sprintf "%.3f" , $self->{res}->{$key}->{hll}->estimate();
}

# Return the estimated entropy of a field
sub entropy {
    my ($self,$key) = @_;

    my %values             = $self->{res}->{$key}->{top}->counts;
    my $sample_count       = keys %values;
    my $sample_cardinality = floor($self->get_key_uniq($key));

    my $is_exact = $sample_count == $sample_cardinality ? 1 : 0;

    my $cnt = 0;
    my $has_unit_values = 0;

    for my $k (keys %values) {
        $cnt += $values{$k};
        $has_unit_values = 1 if $values{$k} == 1;
    }

    my $missing_values = $sample_cardinality - $sample_count;

    if ($missing_values > 0 && ! $has_unit_values) {
        print STDERR "Statistics::TopK bin not big enough to estimate the entropy\n";
        print STDERR "Increate --topk to a value > " . $self->topk . "\n";
        return 'n/a';
    }

    $cnt += $missing_values;

    return 'n/a' unless $cnt > 0;

    my $h = 0;
    for my $k (keys %values) {
        my $p = $values{$k}/$cnt;
        $h += $p * log($p)/log(2);
    }

    if ($has_unit_values) {
        my $p = 1 / $cnt;
        $h += $missing_values * $p * log($p)/log(2);
    }

    return sprintf "%.1f/%.1f" , -1 * $h ,log($cnt)/log(2);
}

sub commit {
    my ($self) = shift;

    my @keys = split(/,/,$self->fields);

    my $fields = [qw(name count zeros zeros% min max mean median mode variance stdev uniq entropy)];

    my $exporter = Catmandu->exporter(
                        $self->as,
                        fields => $fields,
                        file => $self->file
                   );

    for my $key (@keys) {
        my $stats = {};
        $stats->{name} = $key;

        my $val  = $self->get_key_counts($key);

        $stats->{count}    = defined($val) && @$val ? List::Util::sum0(@$val) : 'n/a';
        $stats->{min}      = defined($val) && @$val ? List::Util::min(@$val) : 'n/a';
        $stats->{max}      = defined($val) && @$val ? List::Util::max(@$val) : 'n/a';
        $stats->{mean}     = defined($val) && @$val ? '' . Statistics::Basic::mean($val) : 'n/a';
        $stats->{median}   = defined($val) && @$val ? '' . Statistics::Basic::median($val) : 'n/a';
        $stats->{mode}     = defined($val) && @$val ? '' . Statistics::Basic::mode($val) : 'n/a';
        $stats->{variance} = defined($val) && @$val ? '' . Statistics::Basic::variance($val) : 'n/a';
        $stats->{stdev}    = defined($val) && @$val ? '' . Statistics::Basic::stddev($val) : 'n/a';

        my ($zeros,$zerosp) = ('n/a','n/a');

        if (defined($val) && @$val) {
            $zeros  = int(grep {$_ == 0} @$val);
            $zerosp = sprintf "%.1f" , @$val > 0 ? 100 * $zeros / int(@$val) : 100;
        }

        $stats->{zeros}    = $zeros;
        $stats->{'zeros%'} = $zerosp;

        $stats->{uniq}     = defined($val) && @$val ? $self->get_key_uniq($key) : 'n/a';
        $stats->{entropy}  = defined($val) && @$val ? $self->entropy($key) : 'n/a';

        $exporter->add($stats);
    }

    $exporter->commit;
}

1;

=head1 NAME

Catmandu::Exporter::Stat - a statistical export

=head1 SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu convert -v JSON to Stat --fields isbn

    # Export the statistics as YAML
    cat data.json | catmandu convert -v JSON to Stat --fields isbn --as YAML

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

=item as Table | CSV | YAML | JSON | ...

By default the statistics are exported in a CSV format. The use 'as' option to change the
export format.

=back

=head1 SEE ALSO

L<Catmandu::Exporter> , L<Statistics::Basic>

=cut

1;
