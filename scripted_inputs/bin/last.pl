#!/usr/bin/perl

use warnings;
use strict;
use Time::Local qw(timelocal);

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my $command = "/usr/bin/last -wF|grep 'pts\/'";

## Forward decls
sub getWork();

my ($h, $m, $s, %output);

for my $line (getWork()){
    %output = ();

    if($line =~ /^(?<user>\w+)\s+(?<tty>[\w\/\d:]+)\s+(?<from>[-:\w\/\d.]+)\s+((?<start_wkday>\w+)\s+(?<start_month>\w+)\s+(?<start_day>\d+)\s+(?<start_time>[\d:]+)\s+(?<start_year>\d+)\s+-\s+(?<end_wkday>\w+)\s+(?<end_month>\w+)\s+(?<end_day>\d+)\s+(?<end_time>[\d:]+)\s+(?<end_year>\d+)\s+\((?<dur>[\d+:]*)\)|(?<start_wkday>\w+)\s+(?<start_month>\w+)\s+(?<start_day>\d+)\s+(?<start_time>[\d:]+)\s+(?<start_year>\d+)\s+(?<still>still\slogged\sin))/){
        @output{qw(user tty from)} = @+{qw(user tty from)};

        ## Convert start time string to unixtime
        ($h, $m, $s) = split(/:/, $+{'start_time'});
        $output{'_time'} = "".timelocal($s, $m, $h, $+{'start_day'}, monthToInt($+{'start_month'}), $+{'start_year'});

        if(defined $+{'still'}){
            ## Record user as still logged in
            $output{'event'} = "currently_logged_in";
            printf "%s\n", to_json_custom(\%output); 
        }
        else{
            ## Record login event
            $output{'event'} = "login";
            printf "%s\n", to_json_custom(\%output); 

            ## Record logout event
            $output{'event'} = "logout";
            $output{'duration'} = $+{'dur'};

            ## Convert end time string to unixtime
            ($h, $m, $s) = split(/:/, $+{'end_time'});
            $output{'_time'} = "".timelocal($s, $m, $h, $+{'end_day'}, monthToInt($+{'end_month'}), $+{'end_year'});

            printf "%s\n", to_json_custom(\%output); 
        }
    }
}

sub getWork(){
    my %current = map { chomp; ($_ => $_) } runCommand($command, $useSamples);
    my $statfile = "/tmp/.last_new.tmp";

    if(-e $statfile){ 
        open(my $fh, "+<", $statfile);

        ## Get cached data
        my @cached = map { chomp; $_ } <$fh>;

        ## Remove data from current that was cached last time
        delete @current{@cached};

        ## Go back to start of file and write new data while
        ## truncating old data.
        seek($fh, 0, 0);
        printf $fh "%s\n", join("\n", (@cached, keys(%current)));
        truncate($fh, tell($fh));
    }
    else{
        ## Save all stats to cache
        open(my $fh, ">", $statfile);
        printf $fh "%s\n", join("\n", keys(%current));
    }

    return values(%current);
}

