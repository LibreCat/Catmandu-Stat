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

my $file = "";

my $exporter = $pkg->new(fields => 'name,age,x,foo' , file => \$file);

isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

ok $file , "answer ok";

is($exporter->count, 6, "Count ok");

$file = "";

my $exporter2 = $pkg->new(fields => 'name,age,x,foo' , values => 1, file => \$file);

isa_ok $exporter2, $pkg;

$exporter2->add($_) for @$data;
$exporter2->commit;

ok $file , "answer ok";

is($exporter2->count, 6, "Count ok");

done_testing 8;
