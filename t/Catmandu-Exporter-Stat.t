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
 {"age"=>"44"} ,
 {"foo"=>undef} ,
];

my $answer =<<EOF;
| name | count | zeros | zeros% | min | max | mean | median | mode   | variance | stdev | uniq | entropy |
|------|-------|-------|--------|-----|-----|------|--------|--------|----------|-------|------|---------|
| name | 3     | 3     | 50.0   | 0   | 1   | 0.5  | 0.5    | [0, 1] | 0.25     | 0.5   | 1    | 1.0/2.6 |
| age  | 1     | 5     | 83.3   | 0   | 1   | 0.17 | 0      | 0      | 0.14     | 0.37  | 1    | 0.7/2.6 |
| x    | 0     | 6     | 100.0  | 0   | 0   | 0    | 0      | 0      | 0        | 0     | 0    | 0.0/2.6 |
| foo  | 0     | 6     | 100.0  | 0   | 0   | 0    | 0      | 0      | 0        | 0     | 0    | 0.0/2.6 |
EOF

my $file = "";

my $exporter = $pkg->new(fields => 'name,age,x,foo' , file => \$file);

isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

is $file , $answer , "answer ok";

is($exporter->count, 6, "Count ok");

$file = "";

my $answer2 =<<EOF;
| name | count | zeros | zeros% | min | max | mean | median | variance | stdev | uniq | entropy |
|------|-------|-------|--------|-----|-----|------|--------|----------|-------|------|---------|
| name | 3     | 1     | 25.0   | 0   | 3   | 1.5  | 1.5    | 2.25     | 1.5   | 1    | 0.8/2.0 |
| age  | 1     | 0     | 0.0    | 1   | 1   | 1    | 1      | 0        | 0     | 1    | 0.0/0.0 |
| x    | n/a   | n/a   | n/a    | n/a | n/a | n/a  | n/a    | n/a      | n/a   | n/a  | n/a     |
| foo  | 0     | 1     | 100.0  | 0   | 0   | 0    | 0      | 0        | 0     | 0    | 0.0/0.0 |
EOF

my $exporter2 = $pkg->new(fields => 'name,age,x,foo' , values => 1, file => \$file);

isa_ok $exporter2, $pkg;

$exporter2->add($_) for @$data;
$exporter2->commit;

is $file , $answer2 , "answer2 ok";

is($exporter2->count, 6, "Count ok");

done_testing 8;
