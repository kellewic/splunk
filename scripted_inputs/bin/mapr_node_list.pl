#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 1;
my $command = "maprcli node list -json";
my @out = runCommand($command, $useSamples);

my $data = from_json_custom(join('', @out));

my $ms = 0;
my $ips;

for my $d (@{$data->{'data'}}){
    $d->{'_time'} = getTime($ms++);

    $ips = $d->{'ip'};
    if (ref($ips) eq "ARRAY"){
        $d->{'ip'} = join(',', @{$ips});
    }

    printf "%s\n", to_json_custom($d);
}

