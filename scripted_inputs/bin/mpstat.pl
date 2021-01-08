#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my @out = runCommand("/usr/bin/sar -P ALL 60 1", $useSamples);

exit if scalar(@out) == 0;

## Get rid of all header stuff
shift @out until $out[0] =~ /^\d+:\d+:\d+.*?(?:all|\d+)\s+\d+/;

## Create a function to force a value into a range of 0 to 100
my $forcePercentRange = getPctRangeFactory();

my $ms = 0;
while (@out && (my $line = shift @out) !~ /^.*Average/){
    next if $line !~ /^\d+/;
	my (undef, undef, $cpu, $usr, $nice, $sys, $iowait, $steal, $idle) = (split(/\s+/, $line));

    ($usr, $nice, $sys, $iowait, $steal, $idle) = map { $forcePercentRange->($_) } ($usr, $nice, $sys, $iowait, $steal, $idle);

    printf("%s\n", to_json_custom({
        '_time' => getTime($ms++),
        'usr' => $usr,
        'nice' => $nice,
        'sys' => $sys,
        'iowait' => $iowait,
        'steal' => $steal,
        'idle' => $idle,
        'id' => $cpu eq 'all' ? $cpu : toNum($cpu),
    }));
}

