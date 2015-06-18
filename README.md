# NAME

Catmandu::Stat - Catmandu modules for working with statistical data

# SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu convert JSON to Stat --fields isbn

    # Calculate statistics on the uniqueness of ISBN numbers in the dataset
    cat data.json | catmandu convert JSON to Stat --fields isbn --values 1

    # Export the statistics as YAML
    cat data.json | catmandu convert JSON to Stat --fields isbn --values 1 --as YAML

    # Preprocess data and calculate statistics
    catmandu convert MARC to Stat --fix 'marc_map(020a,isbn)' --fields isbn --values 1 < data.mrc
    
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

- [Catmandu::Exporter::Stat](https://metacpan.org/pod/Catmandu::Exporter::Stat)
- [Catmandu::Fix::stat\_mean](https://metacpan.org/pod/Catmandu::Fix::stat_mean)
- [Catmandu::Fix::stat\_median](https://metacpan.org/pod/Catmandu::Fix::stat_median)
- [Catmandu::Fix::stat\_stddev](https://metacpan.org/pod/Catmandu::Fix::stat_stddev)
- [Catmandu::Fix::stat\_variance](https://metacpan.org/pod/Catmandu::Fix::stat_variance)

# EXAMPLES

The Catmandu::Stat distribution includes a CSV file on the Sacramento crime rate in January 2006,
"t/SacramentocrimeJanuary2006.csv" also available at 
http://samplecsvs.s3.amazonaws.com/SacramentocrimeJanuary2006.csv

To view statistics on the fields available in this file type:

    $ catmandu convert CSV to Stat < t/SacramentocrimeJanuary2006.csv

    | name          | count | zeros | zeros% | min | max | mean | median | mode | variance | stdev | uniq | entropy   |
    |---------------|-------|-------|--------|-----|-----|------|--------|------|----------|-------|------|-----------|
    | address       | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 5492 | 12.1/12.9 |
    | beat          | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 20   | 4.3/12.9  |
    | cdatetime     | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 5094 | 12.0/12.9 |
    | crimedescr    | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 304  | 6.2/12.9  |
    | district      | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 6    | 2.6/12.9  |
    | grid          | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 539  | 8.5/12.9  |
    | latitude      | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 5296 | 12.0/12.9 |
    | longitude     | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 5280 | 12.0/12.9 |
    | ucr_ncic_code | 7584  | 0     | 0.0    | 1   | 1   | 1    | 1      | 1    | 0        | 0     | 88   | 4.1/12.9  |

The file has 7584 rows where and all the fields `address` to `ucr_ncic_code` contain values.
Each field has only one value (no arrays available in the CSV file). The are 5492 unique 
addresses in the CSV file. The `district` field has the lowest entropy, most of its values are
shared among many rows.

To view statistics on the values available in the file type:

     $ catmandu covert CSV to Stat --values 1 < t/SacramentocrimeJanuary2006.csv
    
     | name          | count | zeros | zeros% | min | max  | mean  | median | variance  | stdev  | uniq | entropy   |
     |---------------|-------|-------|--------|-----|------|-------|--------|-----------|--------|------|-----------|
     | address       | 7584  | 0     | 0.0    | 1   | 47   | 1.38  | 1      | 2.39      | 1.55   | 5492 | 12.1/12.9 |
     | beat          | 7584  | 0     | 0.0    | 42  | 521  | 379.2 | 396    | 10,566.06 | 102.79 | 20   | 4.3/12.9  |
     | cdatetime     | 7584  | 0     | 0.0    | 1   | 24   | 1.49  | 1      | 1.67      | 1.29   | 5094 | 12.0/12.9 |
     | crimedescr    | 7584  | 0     | 0.0    | 1   | 653  | 24.95 | 4      | 4,755.33  | 68.96  | 304  | 6.2/12.9  |
     | district      | 7584  | 0     | 0.0    | 868 | 1575 | 1,264 | 1,260  | 53,900    | 232.16 | 6    | 2.6/12.9  |
     | grid          | 7584  | 0     | 0.0    | 1   | 115  | 14.07 | 10     | 193.79    | 13.92  | 539  | 8.5/12.9  |
     | latitude      | 7584  | 0     | 0.0    | 1   | 47   | 1.43  | 1      | 2.77      | 1.66   | 5296 | 12.0/12.9 |
     | longitude     | 7584  | 0     | 0.0    | 1   | 47   | 1.44  | 1      | 2.78      | 1.67   | 5280 | 12.0/12.9 |
     | ucr_ncic_code | 7584  | 0     | 0.0    | 1   | 2470 | 86.18 | 12     | 81,157.83 | 284.88 | 88   | 4.1/12.9  |

There are 304 unique crimes (`crimedescr`) in the data set. Some crimes are found 653 times in the dataset.
Four types of crime comprise 50% of the dataset (`median`).

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
