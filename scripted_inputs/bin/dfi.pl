#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my @out = runCommand("df -li", $useSamples);
shift @out;

my $time = getTime();
my $forcePercentRange = getPctRangeFactory();
my $ms = 0;

for (my $x=0; $x < @out; $x++){
    my $line = $out[$x];
    chomp($line);
    next if isblank($line);

    ## LVM lines are usually broken into the mapper name
    ## and the actual data line so we need to stich them
    ## together. Check for whitespace in case the line
    ## is not broken into two lines.
    if ($line =~ /dev\/mapper|vg_/ && $line !~ /\s/){
        $line .= $out[++$x];
        chomp($line);
    }

    my ($fs, $blocks, $used, $avail, $pct, $mount) = split(/\s+/, $line);
    chop($pct);

    printf "%s\n", to_json_custom({
        '_time' => getTime($ms++),
        'fs' => $fs,
        'mount' => $mount,
        'inodes' => toNum($blocks),
        'used' => toNum($used),
        'avail' => toNum($avail),
        'pct' => $forcePercentRange->($pct)
    });
}

