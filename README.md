# NAME

Catmandu::Stat - Catmandu modules for working with statistical data

# SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu JSON to Stat --keys isbn

    # Calculate statistics on the uniqueness of ISBN numbers in the dataset
    cat data.json | catmandu JSON to Stat --keys isbn --values 1

    # Export the statistics as YAML
    cat data.json | catmandu JSON to Stat --keys isbn --values 1 --as YAML

    # Or in fix files

    # Calculate the mean of foo. E.g. foo => [1,2,3,4]
    stat_mean(foo)  # foo => '2.5'

    # Calculate the median of foo. E.g. foo => [1,2,3,4]
    stat_median(foo)  # foo => '2.5'

    # Calculate the standard deviation of foo. E.g. foo => [1,2,3,4]
    stat_stddev(foo)  # foo => '1.12'

    # Calculate the variance of foo. E.g. foo => [1,2,3,4]
    stat_variance(foo)  # foo => '1.25'

# MODULES

- [Catmandu::Fix::stat\_mean](https://metacpan.org/pod/Catmandu::Fix::stat_mean)
- [Catmandu::Fix::stat\_median](https://metacpan.org/pod/Catmandu::Fix::stat_median)
- [Catmandu::Fix::stat\_stddev](https://metacpan.org/pod/Catmandu::Fix::stat_stddev)
- [Catmandu::Fix::stat\_variance](https://metacpan.org/pod/Catmandu::Fix::stat_variance)

# SEE ALSO

[Catmandu](https://metacpan.org/pod/Catmandu),
[Catmandu::Fix](https://metacpan.org/pod/Catmandu::Fix),

# AUTHOR

Patrick Hochstenbach, `<patrick.hochstenbach at ugent.be>`

# LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
