use Cwd qw(abs_path);
use File::Basename qw(dirname);
use FindBin;
use JSON;

## Make the _time key the first one in the JSON
## Takes in a hash reference with all the data
sub to_json_custom {
    my $json = to_json($_[0]);

    ## Extract _time key from JSON
    $json =~ s/("_time"\s*:\s*".*?"\s*),?//;
    $time = $1;

    if (length($time) > 0){
        ## Put _time key at head of JSON
        $json =~ s/^\{/{$time,/;
    }

    ## For cases where _time was at end of JSON, remove training comma
    $json =~ s/,\}$/}/;

    return $json;
}

## Transform JSON data to a hash reference
sub from_json_custom {
    return decode_json($_[0]);
}

## Get unixtime
sub getTime {
    my ($ms) = @_;

    defined($ms) ?
        sprintf("%d.%03d", time(), toNum($ms)) :
        sprintf("%d", time());
}

## Create a factory to force a value to a lower and upper bound
##
## my $f = forceRangeFactory(0, 100)
## $f->(101)  ## returns 100
##
sub forceRangeFactory {
    my ($lower, $upper) = @_;
    $lower = toNum($lower);
    $upper = toNum($upper);

    return sub {
        my ($val) = toNum($_[0]);
        return ($val < $lower) ? $lower : ($val > $upper) ? $upper : $val;
    }
}

sub getPctRangeFactory { forceRangeFactory(0, 100); }

## Ensure value is output as a number
sub toNum { 0+$_[0]; }

## Turn month strings into integers
my %months = (
    'jan' => 0,
    'feb' => 1,
    'mar' => 2,
    'apr' => 3,
    'may' => 4,
    'jun' => 5,
    'jul' => 6,
    'aug' => 7,
    'sept' => 8,
    'sep' => 8,
    'oct' => 9,
    'nov' => 10,
    'dec' => 11,
    'january' => 0,
    'february' => 1,
    'march' => 2,
    'april' => 3,
    'june' => 5,
    'july' => 6,
    'august' => 7,
    'september' => 8,
    'october' => 9,
    'november' => 10,
    'december' => 11,
);
sub monthToInt { $months{lc($_[0])}; }

## Run command with given args and kwargs
sub runCommand {
    my ($cmd, $sample, $sample_dir) = @_;
    my @out = ();
    $sample_dir ||= "../script_samples/bin";

    if (defined($sample) && $sample){
        my $samples_dir = sprintf("%s/%s", dirname(abs_path(__FILE__)), $sample_dir);
        (my $script = $FindBin::Script) =~ s/\..+$//;
        my $filename = sprintf("%s/%s.sample%d", $samples_dir, $script, $sample);

        if (-e $filename){
            open(my $fh, '<', $filename);
            @out = <$fh>;
            close($fh);
        }
    }
    else{
        @out = `$cmd`;
    }

    return wantarray ? @out : join('', @out);
}

## Checks string or array ref for emptyness
sub isblank {
    my ($line) = @_;
    my $val = 0;

    if (ref($line) eq 'ARRAY'){
        ## If array is empty
       if (0+@$line == 0){
            $val = 1;
        } 
        else {
            ## If first index has no length
            if (length($line->[0]) == 0){
                $val = 1;
            }
        }
    }
    else{
        ## If string is empty
        if (ref($line) eq 'SCALAR' && length($$line) == 0){
            $val = 1;
        }
        elsif (length($line) == 0){
            $val = 1;
        }
    }

    return $val;
}

## Trim strings
sub _trim {
    my ($str, $left, $right) = @_;

    $str =~ s/^\s+// if $left;
    $str =~ s/\s+$// if $right;

    return $str;
}
sub ltrim { _trim($_[0], 1, 0); }
sub rtrim { _trim($_[0], 0, 1); }
sub trim { _trim($_[0], 1, 1); }

