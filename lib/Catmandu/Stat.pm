package Catmandu::Stat;

=head1 NAME

Catmandu::Stat - Catmandu modules for working with statistical data

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu convert JSON to Stat --keys isbn

    # Calculate statistics on the uniqueness of ISBN numbers in the dataset
    cat data.json | catmandu convert JSON to Stat --keys isbn --values 1

    # Export the statistics as YAML
    cat data.json | catmandu convert JSON to Stat --keys isbn --values 1 --as YAML

    # Or in fix files

    # Calculate the mean of foo. E.g. foo => [1,2,3,4]
    stat_mean(foo)  # foo => '2.5'

    # Calculate the median of foo. E.g. foo => [1,2,3,4]
    stat_median(foo)  # foo => '2.5'

    # Calculate the standard deviation of foo. E.g. foo => [1,2,3,4]
    stat_stddev(foo)  # foo => '1.12'

    # Calculate the variance of foo. E.g. foo => [1,2,3,4]
    stat_variance(foo)  # foo => '1.25'

=head1 MODULES

=over

=item * L<Catmandu::Exporter::Stat>

=item * L<Catmandu::Fix::stat_mean>

=item * L<Catmandu::Fix::stat_median>

=item * L<Catmandu::Fix::stat_stddev>

=item * L<Catmandu::Fix::stat_variance>

=back

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Fix>,

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;