#!/usr/bin/perl

use warnings;
use strict;
use Time::Local;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;

my $cmd = 'vmstat -an -t -SM 60 2 && echo -n PAGESIZE: && getconf PAGESIZE &&';
$cmd .= 'vmstat -s |grep -E "pages|boot"';

my @out = runCommand($cmd, $useSamples);

my $output = {};
my $got_summary_line = 0;
my $ms = 0;

for my $line (@out){
    chomp($line);
    next if isblank($line);
    next if $line =~ /free|memory/;

    ## Skip the first line of data as it's averages since last reboot
    if ($got_summary_line == 0){
        $got_summary_line = 1;
        next;
    }

    $line = trim($line);

    if ($line =~ /(?:\d+\s+){6,}/){
        my ($wr, $us, $mem_swapped, $mem_free, $mem_inactive, $mem_active, $swap_si, 
            $swap_so, $io_bi, $io_bo, $sys_in, $sys_cs, $cpu_us, $cpu_sy, 
            $cpu_id, $cpu_wa, $cpu_st, $date) = map{
                my $v = $_;
                if ($v =~ /^\d+$/){
                    $v = toNum($v);
                }
                $v;
            } split(/\s+/, $line, 18);

        ## Since there is a delay to get past the average line, we tell
        ## vmstat to include a datetime and we use this as our _time.
        my @p = $date =~ /^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)(?:\s+[A-Z]+)?$/;
        $p[1]--;

        $output = {
            '_time' => sprintf("%s.%03d", timelocal(reverse(@p)), $ms++),
            'procs_r' => $wr,
            'procs_b' => $us,
            'mem_swapped' => $mem_swapped,
            'mem_free' => $mem_free,
            'mem_inactive' => $mem_inactive,
            'mem_active' => $mem_active,
            'swap_si' => $swap_si,
            'swap_so' => $swap_so,
            'io_bi' => $io_bi,
            'io_bo' => $io_bo,
            'sys_in' => $sys_in,
            'sys_cs' => $sys_cs,
            'cpu_us' => $cpu_us,
            'cpu_sy' => $cpu_sy,
            'cpu_id' => $cpu_id,
            'cpu_wa' => $cpu_wa,
            'cpu_st' => $cpu_st,
        };
    }
    elsif ($line =~ /^(?:PAGESIZE):\d+$/){
        my ($label, $value) = split(/:/, $line);
        $output->{lc $label} = toNum($value);
    }
    elsif ($line =~ /(?:pages\s+(?:paged|swapped)\s+(?:in|out)|boot time)/){
        my ($value, $label) = split(/\s/, $line, 2);
        $label =~ s/\s/_/g;
        $output->{$label} = toNum($value);
    }
}

printf "%s\n", to_json_custom($output);

