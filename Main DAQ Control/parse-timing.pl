#!perl -w

# If you're having troubles with this script, remove the # from
# the next line

#$DEBUG = 1;

my $usage = "Usage: parse-timing.pl <input file> [<output file>]\n";
my $lockfile = "parselock.txt";

get_lock();

my $inputfile = shift || fail($usage);
my $outputfile = shift || "parsed.txt";

my $searchstr = '\$[\w\d+\$\-\*\.\/]+';

open (INTEXT, $inputfile) or fail("Unable to open '$inputfile': $!");

if ($DEBUG) {
    print "Reading '$inputfile'.\n"; #DEBUG
}

# First, handle any Perl definitions. Any line that begins with "$",
#  "@", or "#" is okay. This is for "$var = value" kind of definitions,
#  "#" style comments, and Perl commands such as "require" prefaced
#  with a "@".
while (<INTEXT>) {
    last unless /^\s*\$\w+\s*=\s*/ or /^\s*@/ or /^\s*#/;
    chop;
    if (/^\s*@(.*)$/) {
	$_ = $1;
    }
    eval;
}

# Skip blank lines
if ($_ eq "\n") {
    1 while (($_ = <INTEXT>) eq "\n");
}

open(OUTTEXT, ">".$outputfile) or fail("Unable to open '$outputfile': $!");

if ($DEBUG) {
    print "Writing '$outputfile'.\n"; #DEBUG
}

# Process the rest of the file, starting with the already-read line
if (!(/^\#/)) {
    s/#.*$//;
    s/$searchstr/eval $&/eg;
    s/\s{2,}/ /g;     # Collapse all whitespace to a single space
    s/\s+$//;         # Get rid of leading or trailing whitespace
    s/^\s+//;
    print OUTTEXT $_."\n";
}

while (<INTEXT>) {
    next if (/^\#/);  # Skip lines that begin with a '#'
    s/#.*$//;
    s/$searchstr/eval $&/eg;
    s/\s{2,}/ /g;     # Collapse all whitespace to a single space
    s/\s+$//;         # Get rid of leading or trailing whitespace
    s/^\s+//;
    print OUTTEXT $_."\n";
}

close INTEXT;
close OUTTEXT;
remove_lock();

if ($DEBUG) {
    sleep 5;
}

#####
# Simple fail handler
#####

sub fail {
    my $message = shift || "Died in parse-timing.pl."; 
    print "$message\n";
    if ($DEBUG) {
	sleep 5;
    }
    remove_lock();
    exit 1;
}

#####
# Win95 doesn't support flock(), so we'll wing it
#####

sub get_lock {
    my $i = 0;
    while (open (GLOBAL_LOCK, "<$lockfile")) {
	(++$i < 20) || fail("Took too long waiting for semaphore lock in parse-timing.pl.");
	close GLOBAL_LOCK;
	sleep 1;
    }
    open (GLOBAL_LOCK, ">$lockfile") || fail("Unable to open semaphore lock file $lockfile in parse-timing.pl.");
    @mytime = localtime;
    $mon = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$mytime[4]];
    $year = $mytime[5]+1900;
    print GLOBAL_LOCK "Locked by parse-timing.pl at $mytime[2]:$mytime[1]:$mytime[0] $mytime[3] $mon $year.\n";
    close GLOBAL_LOCK;
}

sub remove_lock {
    unlink $lockfile || fail("Unable to delete semaphore lock file $lockfile in parse-timing.pl.");
}
