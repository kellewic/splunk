#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my $command = "/usr/bin/maprcli volume list -columns volumename,quota,used,mountdir,nameContainerSizeMB,volumeid,numreplicas |grep -v 'local\\\|/home/'";
my @out = runCommand($command, $useSamples);

my $time = getTime();

for my $line (@out){
    next if $line =~ /nameContainerSizeMB/;

    ## ENV1 output
	my ($quota, $mount, $nameContainerSizeMB, $numreplicas, $volumeid, $used, $vol) = (split(/\s+/, $line));

    ## ENV2 output
    if ($mount !~ /\// && ($used !~ /^\d+$/ || $vol eq "")){
        ($nameContainerSizeMB, $vol, $numreplicas, $quota, $volumeid, $mount, $used) = (split(/\s+/, $line));

        if ($mount =~ /^\d+$/){
            ($nameContainerSizeMB, $vol, $numreplicas, $quota, $volumeid, $used) = (split(/\s+/, $line));
            $mount = "";
        }
    }

    my $useSamples = 0;
    my $command = "/usr/bin/maprcli dump volumeinfo -volumename $vol -json | grep 'AccessTime\\\|NumInodesInUse'";
    my @data = runCommand($command, $useSamples);

    my ($accessTime, $numInodesInUse) = ("", "");
    my ($x, $inodes);

    for my $line (@data){
        $line =~ s/(?:"|\n|,$)//g;

        if ($line =~ /AccessTime/){
            ($x, $accessTime) = split(/:/, $line, 2);
        }
        elsif ($line =~ /NumInodesInUse/){
            if ($numInodesInUse eq ""){
                $numInodesInUse = 0;
            }

            ($x, $inodes) = split(/:/, $line, 2);
            $numInodesInUse += $inodes;
        }
    }

    printf "%s\n", to_json_custom({
        '_time' => $time,
        'vol' => $vol,
        'quota' => $quota,
        'mount' => $mount,
        'used' => $used,
        'nameContainerSizeMB' => $nameContainerSizeMB,
        'volumeid' => $volumeid,
        'numreplicas' => $numreplicas,
        'accessTime' => $accessTime,
        'numInodesInUse' => $numInodesInUse
    });
}

