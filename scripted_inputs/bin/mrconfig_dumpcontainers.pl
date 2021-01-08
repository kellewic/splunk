#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my $command = "/opt/mapr/server/mrconfig sp list -v";
my @out = runCommand($command, $useSamples);

for my $line (@out){
    $line =~ s/, /,/g;

    if ($line =~ /^\s*SP\s+(\d+):\s+name\s+(SP\d+),(.*?),size\s+(.*?),free\s+(.*?),path\s+(.*?),.*?disks\s+(.*)\s*/){
        my ($sp, $name, $status, $size, $free, $disk, $disks) = ($1, $2, $3, $4, $5, $6, $7);

        $useSamples = 0;
        $command = "/opt/mapr/server/mrconfig info containers rw $disk";
        my @out = runCommand($command, $useSamples);      

        my $containers = '0';

        for my $cline (@out){
            if ($cline =~ /^.*?RW.+containers:\s+\d+/){
                $cline =~ s/^\s*.*?:\s*//;
                $cline =~ s/\s+$//g;
                $cline =~ s/\s+/ /g;

                $containers = $cline;
                last;
            }
        }

        printf "sp=%s,name=%s,status=%s,size=%s,free=%s,disk=%s,disks=%s,container=%s\n", $sp, $name, $status, $size, $free, $disk, $disks, $containers;
    }
}

