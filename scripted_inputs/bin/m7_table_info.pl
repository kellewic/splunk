#!/usr/bin/perl

## Runs the MapR cli command against a list of tables sent in by 
## the corresponding Bash script.

use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $info = '';
my $loopKiller = 0;
my $killLoopAt = 1;
BEGIN {
    ## Override the sub so JSON module doesn't cause the script to terminate due to bad JSON data
    *Carp::croak = sub {
        my ($error) = @_;

        ## Keep counter in case other JSON issues come up we haven't accounted for yet.
        if ($loopKiller < $killLoopAt){
            $loopKiller++;
            $info =~ s/"(?:end|start)key":\s*".*?",//g;
            $info =~ s/[\t\n]+//g;

            ## Since $info is a package-level variable, changing it here affects the variable
            ## being processed for JSON data. Jump back to where the error occurred to try
            ## to re-process the data.
            goto RESUME_PROCESSING;
        }
        else {
            ## We weren't able to fix the JSON string so log the error to Splunk _internal
            ## and skip these records.
            print STDERR "$error - $info\n";
            $info = '';
            goto RESUME_PROCESSING;
        }
    };
}
## Don't move the below line above this point
use warnings;

my $ms = 0;
my $timeout = 30;
my ($fh);

## This must match where the Bash script writes its data
my $tables_file = "/tmp/m7_table_info_targets.txt";

## Bash script sends these in
my $start_index = $ARGV[0];
my $end_index = $ARGV[1];
my $run_id = sprintf("%s.%s", $ARGV[2], $$);

## Must match the location where the Bash script looks for output
my $output_file = "/tmp/splunk_m7_table_output/m7_table_info_$$.json";

## Make sure we have start and end points
if (!defined($start_index) || !defined($end_index)){
    exit(5);
}

## Read only the lines we need; avoids reading the entire file to memory
my $count = -1;
my @tables = ();

open ($fh, '<', $tables_file);
while(my $line = <$fh>){
    $count++;
    next if $count < $start_index;
    push @tables, $line;
    last if $count >= $end_index;
}
close $fh;

## Open our file for writing command results
$|++;
open ($fh, '>', $output_file);

for my $line (@tables){
    next if isblank($line);
    chomp($line);

    my $useSamples = 0;
    my $command = "maprcli table region list -path $line -json";
    my $startTime = getTime();
    my (@out, $data);
    my $kill = 0;

    eval {
        local $SIG{ALRM} = sub { die "terminated" };
        alarm($timeout);
        @out = runCommand($command, $useSamples);
        alarm(0);
    };

    if ($@){
        $kill = 1;
        $data = {'data' => [{'error' => 'timeout'}]};
    }
    else{
        $info = join('', @out);

        if ($info !~ /\s*\{.*data.*\}/s){
           $data = {'data' => [{'error' => $info}]};
        }
        else{
            ## Reset error counter
            $loopKiller = 0;

            ## Error handling will jump back here after trying to fix $info
            RESUME_PROCESSING:

            ## Skip this record if we couldn't fix $info
            next if $info eq '';

            $data = from_json_custom($info);
        }
    }

    my $endTime = getTime();

    for my $ent (@{$data->{'data'}}){
        $ms = 0 if $ms > 999;
        $ent->{'_time'} = getTime($ms++);
        $ent->{'table_name'} = $line;
        $ent->{'st'} = $startTime;
        $ent->{'et'} = $endTime;
        $ent->{'runid'} = $run_id;

        ## Write results to our output file
        printf $fh "%s\n", to_json_custom($ent);
    }

    if ($kill){
        @out = `ps -ef | grep "$command" | grep root | grep -v 'grep' | awk '{print \$2}'`;
        my $pid = join('', @out);
        $pid =~ s/\s+//g;
        print STDERR "KILLED PROCESS $pid, $line\n";
        kill 'KILL', $pid;
    }
}

## Close our output file
close $fh;

