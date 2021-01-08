#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 1;
my $command = "/usr/bin/mapred queue -list";
my @out = runCommand($command, $useSamples);

my $ms = 0;

for my $line (@out){
    next if $line !~ /Queue Name\s+:\s+(?:root\.)(\w+)/;

    printf "%s\n", to_json_custom({
        '_time' => getTime($ms++),
        'jobQueue' => $1,
    });
}

