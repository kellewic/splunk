#!/usr/bin/perl 

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

## Forward decl
sub parseTime($;);

my $useSamples = 0;
my @out = runCommand(
    "ps o user:12,uid,pid,ppid,psr,%cpu,%mem,vsz,rss,tty,stat,etime,time,comm,args -A --no-header",
    $useSamples
);

my $ms = 0;
my %users = ();

## Create a function to force a value into a range of 0 to 10_000_000 
## It really exists to control the lower bounds
my $forceRange = forceRangeFactory(0, 10000000);

## Force a number into a normal percent range
my $forcePercentRange = getPctRangeFactory();

while ((my $line = shift @out)){
    my ($user, $uid, $pid, $ppid, $psr, $cpu, $mem, $vsz, $rss, $tty,
        $stat, $etime, $time, $command, $args) = map {chomp; $_} split(/\s+/, $line, 15);

    ## Check kthread processes for any mem or cpu usage.
    ## If there is none, then skip it.
    next if $ppid == 2 && $cpu == 0 && $mem == 0;

    $cpu = $forceRange->($cpu);
    $mem = $forcePercentRange->($mem);

    $args =~ s/\s+$//;

    if($uid >= 0 ){
        ## Fix truncated commands - Linux only keeps 15 characters in /proc/PID/comm
        if (length($command) == 15){
            ## If cmd == [args], then it's not truncated so skip it
            if ($args ne "[$command]"){
                ## Make sure args has cmd as part of its text
                if ($args =~ /^($command.+)[:\]]/){
                    ## Catches entries like 'hald-addon-acpi: listening on acpid socket'
                    $command = $1;
                }
                elsif ($args =~ /^.*\/$command/){
                    ## Catches scripts run via bash, perl, python, etc
                    for my $part (split(/\s+/, $args)){
                        if ($part =~ /$command/){
                            ($command = $part) =~ s/.*\///;
                            last;
                        }
                    }
                }
            }
        }

        ## If args has no spaces, then there are no args - set to undef,
        ## which ends up as null inside the JSON. Backwares compat with
        ## current data already in Splunk.
        $args = undef if ($args !~ /\s/);

        my $cpu_time = parseTime($time);
        my $duration = parseTime($etime);
        $uid = toNum($uid);
        $ppid = toNum($ppid);

        printf "%s\n", to_json_custom({
            '_time' => getTime($ms++),
            'pid' => toNum($pid),
            'ppid' => $ppid,
            'psr' => toNum($psr),
            'cpu' => $cpu,
            'mem' => $mem,
            'vsz' => toNum($vsz),
            'rss' => toNum($rss),
            'tty' => $tty,
            'stat' => $stat,
            'duration' => $duration,
            'cpu_usage' => $cpu_time,
            'util' => sprintf("%.02f", $cpu_time / ($duration || 1)),
            'uid' => $uid,
            'user' => $user,
            'cmd' => $command,
            'args' => $args,
        });

        $users{$user}{'uid'} = $uid;
        $users{$user}{'total_cpu'} += $cpu;
        $users{$user}{'total_mem'} += $mem;
    }
}

for my $user (keys %users){
    ## Ignore users who have used no mem or cpu
    if ($users{$user}{'total_cpu'} > 0 || $users{$user}{'total_mem'} > 0){
        $users{$user}{'_time'} = getTime($ms++);
        $users{$user}{'user'} = $user;

        printf "%s\n", to_json_custom($users{$user});
    }
}

sub parseTime($;){
    my ($sourceTime) = @_;
    my $returnTime = 0;

    if($sourceTime =~ /((?<days>\d+)-)?((?<hours>\d+))?:(?<mins>\d+):(?<secs>\d+)/){
        if($+{days}){
            $returnTime += $+{days} * 24 * 60 * 60;
        }
        if($+{hours}){
            $returnTime += $+{hours} * 60 * 60;
        }
        if($+{mins}){
            $returnTime += $+{mins} * 60;
        }
        if($+{secs}){
            $returnTime += $+{secs};
        }
    }

    return $returnTime;
}

