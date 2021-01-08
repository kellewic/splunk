#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

## Load Common module from same directory
use lib dirname(abs_path(__FILE__));
use Common;

my $useSamples = 0;
my $out = runCommand("/sbin/ifconfig", $useSamples);

my @interfaces = split(/\n\n/, $out);
my $ms = 0;

sub getStatFile { sprintf("/tmp/.ifconfig.%s", $_[0]); }

sub writeStats {
    my (%if) = @_;
    open(FH, ">", getStatFile($if{'id'}));
    print FH to_json(\%if);
    close(FH)
}

sub getStats {
    my (%stats) = @_;
    my %metrics = ();
    my $statfile = getStatFile($stats{'id'});

    if(-e $statfile){ 
        open(FH, "<", $statfile);
        my $last = decode_json(<FH>);
        close(FH);

        $last->{'rx_bytes'} = 0 if !defined($last->{'rx_bytes'});
        $last->{'tx_bytes'} = 0 if !defined($last->{'tx_bytes'});

        if($last->{'rx_bytes'} > $stats{'rx_bytes'} || $last->{'tx_bytes'} > $stats{'tx_bytes'}){
            # Rebooted?
            writeStats(%stats);
            return %stats;
        }

        for my $key (keys %stats){
            if($key ne "id" && $key ne "_time"){
                $last->{$key} = 0 if !defined($last->{$key});
                $metrics{$key} = $stats{$key} - $last->{$key};
            }
        }

        ## Avoid divide by zero error in case the script is run back to back
        ## 0.060 was chosen as it is the average delay of running the script
        ## back to back at the command line.
        my $duration = ($stats{'_time'} - $last->{'_time'}) || 0.060;

        $metrics{'dur'} = $duration;
        $metrics{'rx_KBs'} = sprintf "%.02f", ($metrics{'rx_bytes'} / $duration)/1024;
        $metrics{'tx_KBs'} = sprintf "%.02f", ($metrics{'tx_bytes'} / $duration)/1024;

        writeStats(%stats);
        return %metrics;
    }
    else {
        writeStats(%stats); 
        return %stats;
    }
}

for my $line (@interfaces){
    ## Get each interface as one line of text as the output format can change across
    ## versions of the same OS, but generally the same data will be present.
    $line =~ s/\n//g;
    $line =~ s/ {2,}/ /g;
    trim($line);

    my $time = getTime($ms++);
    my %interface = ('_time' => $time);
    my %stats = (
        '_time' => $time,
        'id' => '',
        'rx_bytes' => 0,
        'rx_pkts' => 0,
        'rx_errors' => 0,
        'rx_dropped' => 0,
        'rx_overruns' => 0,
        'rx_frame' => 0,
        'tx_bytes' => 0,
        'tx_pkts' => 0,
        'tx_errors' => 0,
        'tx_dropped' => 0,
        'tx_overruns' => 0,
        'tx_frame' => 0,
        'tx_col' => 0,
        'tx_queue' => 0,
    );

    if ($line =~ /^(\S+)\s+/){
        (my $id = $1) =~ s/\W$//;
        $interface{'id'} = $id;
        $stats{'id'} = $id;
    }

    if ($line =~ /\sencap:(.+?)\s/){
        $interface{'encap'} = $1;
    }
    elsif ($line =~ /\s\(ethernet\)\s/i){
        $interface{'encap'} = 'Ethernet';
    }
    elsif ($line =~ /\s\(local loopback\)\s/i){
        $interface{'encap'} = 'Local';
    }

    if ($line =~ /((?:[A-z0-9]+:){5}[A-z0-9]+)/){
        ($interface{'hwaddr'} = $1) =~ s/://g;
    }

    if ($line =~ /inet addr:([0-9\.]+)\s+(?:Bcast:([0-9\.]+)\s+)?Mask:([0-9\.]+)/){
        $interface{'ip'} = $1;
        $interface{'bcast'} = $2 if defined($2);
        $interface{'mask'} = $3;
    }
    elsif ($line =~ /inet\s+([0-9\.]+)\s+netmask\s+([0-9\.]+)\s+(?:broadcast\s+([0-9\.]+))?/){
        $interface{'ip'} = $1;
        $interface{'mask'} = $2;
        $interface{'bcast'} = $3 if defined($3);
    }

    if ($line =~ /<?([A-Z\s,]+)>?\s+mtu[:\s]+(\d+)\s+/i){
        ## This must be first since the next s// regex line eats it
        $interface{'mtu'} = $2;
        ($interface{'flags'} = trim($1)) =~ s/,/ /g;
    }

    if ($line =~ /RX packets:(\d+)\s+errors:(\d+)\s+dropped:(\d+)\s+overruns:(\d+)\s+frame:(\d+)/){
        $stats{'rx_pkts'} = $1;
        $stats{'rx_errors'} = $2;
        $stats{'rx_dropped'} = $3;
        $stats{'rx_overruns'} = $4;
        $stats{'rx_frame'} = $5;
    }
    elsif ($line =~ /RX packets (\d+).*?RX errors (\d+) dropped (\d+) overruns (\d+) frame (\d+)/){
        $stats{'rx_pkts'} = $1;
        $stats{'rx_errors'} = $2;
        $stats{'rx_dropped'} = $3;
        $stats{'rx_overruns'} = $4;
        $stats{'rx_frame'} = $5;
    }

    if ($line =~ /TX packets:(\d+)\s+errors:(\d+)\s+dropped:(\d+)\s+overruns:(\d+)\s+carrier:(\d+)\s+collisions:(\d+)\s+txqueuelen:(\d+)/){
        $stats{'tx_pkts'} = $1;
        $stats{'tx_errors'} = $2;
        $stats{'tx_dropped'} = $3;
        $stats{'tx_overruns'} = $4;
        $stats{'tx_frame'} = $5;
        $stats{'tx_col'} = $6;
        $stats{'tx_queue'} = $7;
    }
    elsif ($line =~ /TX packets (\d+).*?TX errors (\d+) dropped (\d+) overruns (\d+) carrier (\d+) collisions (\d+)/){
        $stats{'tx_pkts'} = $1;
        $stats{'tx_errors'} = $2;
        $stats{'tx_dropped'} = $3;
        $stats{'tx_overruns'} = $4;
        $stats{'tx_frame'} = $5;
        $stats{'tx_col'} = $6;
    }

    if ($line =~ /txqueuelen (\d+)/){
        $stats{'tx_queue'} = $1;
    }

    if ($line =~/RX bytes:(\d+).+TX bytes:(\d+)/){
        $stats{'rx_bytes'} = $1;
        $stats{'tx_bytes'} = $2;
    }
    elsif ($line =~ /RX packets \d+ bytes (\d+).+TX packets \d+ bytes (\d+)/){
        $stats{'rx_bytes'} = $1;
        $stats{'tx_bytes'} = $2;
    }

    %stats = getStats(%stats);

    for my $key (keys %stats){
        if ($key ne "_time" && $key ne "id"){
            $interface{$key} = toNum($stats{$key});
        }
    }

    printf "%s\n",to_json_custom(\%interface);
}

