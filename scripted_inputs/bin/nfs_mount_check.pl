#!/usr/bin/perl
## This script determines what NFS mounts are mounted

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my @out = runCommand("cat /proc/mounts |grep nfs |grep addr", $useSamples);

my $time = getTime();
my $ms = 0;

for my $line (@out){
    chomp($line);
    next if isblank($line);

    my ($remote_mount, $local_mount) = split(/\s+/, $line);

    printf "%s\n", to_json_custom({
        '_time' => getTime($ms++),
        'remote_mount' => $remote_mount,
        'local_mount' => $local_mount
    });
}

