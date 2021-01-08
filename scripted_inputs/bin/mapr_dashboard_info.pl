#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my $command = "maprcli dashboard info -json";
my @out = runCommand($command, $useSamples);
my $data = from_json_custom(join('', @out));

my @remove = qw(timeofday timestamp data services cluster);

## Flatten the hash out a bit
for my $entry (@{$data->{'data'}}){
    while (my($k, $v) = (each %$entry)){
        $data->{$k} = $v;
    }
}

## More flattening by taking each service and numbering
## them to make working with these in Splunk easier.
my $count = 1;
my @neededKeys = qw(stopped standby active total failed);
while (my($k, $v) = (each %{$data->{'services'}})){
    $v->{'name'} = $k;

    for my $nk (@neededKeys){
        if (!exists($v->{$nk})){
            $v->{$nk} = 0;
        }
    }

    $data->{"service".$count++} = $v;
}

## Remove keys we don't want going to Splunk
delete @{$data}{@remove};

$data->{'_time'} = getTime();

printf "%s\n", to_json_custom($data);

