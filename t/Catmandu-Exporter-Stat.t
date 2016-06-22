#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::XS ();

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::Stat';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
 {"name"=>"patrick"} ,
 {"name"=>"patrick"} ,
 {"name"=>"patrick"} ,
 {"name"=>undef} ,
 {"age"=>"44",foo=>[]} ,
 {"foo"=>undef} ,
];

my $answer =<<EOF;
| name | count | zeros | zeros% | min | max | mean | median | mode   | variance | stdev | uniq | entropy |
|------|-------|-------|--------|-----|-----|------|--------|--------|----------|-------|------|---------|
| name | 3     | 3     | 50.0   | 0   | 1   | 0.5  | 0.5    | [0, 1] | 0.25     | 0.5   | 1    | 1.0/2.6 |
| age  | 1     | 5     | 83.3   | 0   | 1   | 0.17 | 0      | 0      | 0.14     | 0.37  | 1    | 0.7/2.6 |
| x    | 0     | 6     | 100.0  | 0   | 0   | 0    | 0      | 0      | 0        | 0     | 0    | 0.0/2.6 |
| foo  | 0     | 6     | 100.0  | 0   | 0   | 0    | 0      | 0      | 0        | 0     | 0    | 0.0/2.3 |
EOF

my $file = "";

my $exporter = $pkg->new(fields => 'name,age,x,foo' , file => \$file);

isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

is $file , $answer , "answer ok";

is($exporter->count, 6, "count ok");

done_testing 5;
