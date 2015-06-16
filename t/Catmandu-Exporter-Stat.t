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
 {"name" => "John"} ,
 {"name" => "John"} ,
 {"name" => "John"} ,
 {"name" => "John"} ,
 {"name" => "John"} ,
 {"name" => "John"} ,
 {"name" => "John"} ,
 {"name" => "John"} ,
 {"name" => "Peter"} ,
 {"name" => "Peter"} ,
 {"name" => "Peter"} ,
 {"name" => "Ann"} ,
 {"name" => "Ann"} ,
 {"name" => "Ann"} ,
 {"name" => "Ann"} ,
 {"name" => "Ann"} ,
 {"name" => ["Alice","Ann"] } ,
];

my $answer =<<EOF;
_id,count,max,mean,median,min,stdev,variance,zeros,zeros%
name,18,2,1.06,1,1,0.24,0.06,0,0
age,0,0,0,0,0,0,0,17,100
EOF

my $file = "";

my $exporter = $pkg->new(keys => 'name,age' , file => \$file);

isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

is $file , $answer , "answer ok";

is($exporter->count, 17, "Count ok");

$file = "";

my $answer2 =<<EOF;
_id,count,max,mean,median,min,stdev,variance,zeros,zeros%
name,18,8,4.5,4.5,1,2.69,7.25,0,0
EOF

my $exporter2 = $pkg->new(keys => 'name' , values => 1, file => \$file);

isa_ok $exporter2, $pkg;

$exporter2->add($_) for @$data;
$exporter2->commit;

is $file , $answer2 , "answer ok";

is($exporter2->count, 17, "Count ok");

done_testing 8;
