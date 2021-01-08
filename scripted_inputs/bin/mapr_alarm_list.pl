#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my $command = "maprcli alarm list -summary true";
my @out = runCommand($command, $useSamples);
shift @out;

my $ms = 0;

for my $line (@out){
    next if isblank($line);
    my ($state, $desc, $name, $change);

    if ($line =~ /^(\d+)\s+(.*?\))\s+(.*?)\s+(\d{10,})/){
        ($state, $desc, $name, $change) = ($1, $2, $3, $4);
    }

    if ($line =~ /^(\d{10,})\s+(\d+)\s+(.*?)\s+([A-Z_]+)/){
        ($change, $state, $desc, $name) = ($1, $2, $3, $4);
    }

    if (defined($state) && defined($desc) && defined($name) && defined($change)){
        printf "%s\n", to_json_custom({
            '_time' => getTime($ms++),
            'state' => $state,
            'name' => $name,
            'description' => $desc,
            'state_change_time' => $change/1000,
        });
    }
}

