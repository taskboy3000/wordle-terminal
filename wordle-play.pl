#!/usr/bin/env perl
# A wordle clone
#
# Perl code copyright Joe Johnston <jjohn@taskboy.com>
#
use Modern::Perl;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use Getopt::Long;
use Term::ANSIColor;

our $gCandidateWords = [];

main();

#--------
# Subs
#--------

sub options () {
    my %opts;
    GetOptions(
               "h|help" => \$opts{help},
               "s|word-size=i" => \$opts{wordSize},
               "t|num-turns=i" => \$opts{numTurns},
               "force=s" => \$opts{forcedSecret}, # for debugging
               "d|dictionary=s" => \$opts{dictionaryFile}
              );

    $opts{wordSize} //= 5;
    $opts{numTurns} //= 6;

    if (defined $opts{dictionaryFile}) {
        if (!-e $opts{dictionaryFile}) {
            die("Dictionary file '$opts{dictionaryFile}' not found\n");
        }
    }

    if (!defined $opts{dictionaryFile}) {

        my @searchOrder = ('/usr/share/dict/words', "$FindBin::Bin/words");
        if ($opts{wordSize} == 5) {
            push @searchOrder, "$FindBin::Bin/5-letter-words.txt";
        }

        for my $searchOrder (@searchOrder) {
            if (-e $searchOrder) {
                $opts{dictionaryFile} = $searchOrder;
                last;
            }
        }

        if (!defined $opts{dictionaryFile}) {
            die("Please specify a dictionary file (-d) to use\n");
        }

    }

    return \%opts;
}

sub usage () {
    return <<"EOT";
$0 - play wordle

OPTIONS

-h|help             This screen
-s|word-size INT    Length of the secret word
-t|num-turns INT    Allowed number of guesses
-d|dictionary FILE  Path to UNIX style dictionary file (e.g. /usr/share/dict/words)

EOT
}


sub main () {
    my $opts = options();

    if ($opts->{help}) {
        say usage();
        exit;
    }

    $|++;
    play($opts->{wordSize}, $opts->{numTurns}, $opts->{dictionaryFile}, $opts->{forcedSecret});
}


sub play($wordSize, $turnsLeft, $dictionaryFile, $forcedSecret) {
    my $numTurns = $turnsLeft;

    say "Let's play " . color('bold red') . 'WORDLE - 1981' . color('reset');
    say "Choosing secret word from $dictionaryFile";
    my $secret = chooseWordBySize($dictionaryFile, $wordSize);

    if (defined $forcedSecret) {
        $secret = $forcedSecret;
    }

    while ($turnsLeft) {
        my $guess = prompt("> ", $wordSize, $turnsLeft);

        orient($secret => $guess);

        if ($guess eq $secret) {
            congradulate($turnsLeft, $numTurns);
            return;
        }


        $turnsLeft -= 1;
    }

    console($secret);
}


sub orient ($secret, $guess) {
    # black_on_yellow for right letter, wrong place
    # white_on_green for right letter, right place
    # normal for wrong letter

    my @guesses = split //, $guess;
    my @secrets = split //, $secret;
    print "\t";

    for (my $i = 0; $i < @guesses; $i++) {
        my $pos = index($secret, $guesses[$i]);

        if ($guesses[ $i ] eq $secrets[ $i ]) {
            print color('white on_green') . $guesses[$i] . color('reset');
            next;
        }

        # Is this guess letter in the secret?
        # Is this guess letter not in the right position?
        # Does this guess letter appear later at the right position?
        if ( $pos > -1 && $pos != $i && $guesses[ $i ] ne $guesses[ $pos ]) {
            print color('white on_yellow') . $guesses[ $i ] . color('reset');
            next;
        }

        print $guesses[ $i ];
    }
    print "\n";
}


sub prompt ($prompt, $wordSize, $turnsLeft) {
    my $guess = "";
    while (!$guess) {
        print "[$turnsLeft]> ";
        my $ans = readline();
        $ans //= '';
        chomp($ans);
        if (length($ans) != $wordSize) {
            say ">> Guess must be $wordSize characters, not " . length($ans);
            next;
        }

        if ($ans =~ /[^a-z]/) {
            say ">> Guess must be letters only (no punctuation)";
            next;
        }

        if (!isDictWord(lc($ans))) {
            say ">> '$ans' does not appear in my dictionary";
            next;
        }

        $guess = lc($ans);
    }

    return $guess;
}


sub isDictWord ($word) {
    $word = lc $word;

    for my $dictWord (@$gCandidateWords) {
        if ($word eq $dictWord) {
            return 1;
        }
    }

    return;
}


sub congradulate ($turnsLeft, $totalTurns) {
    if ($turnsLeft == 0) {
        say color('bold_blue') . 'Phew!' . color('reset');
        return;
    }

    my $percent = int(($turnsLeft / $totalTurns) * 100);

    if ($percent == 100) {
        say color('red on_bright_yellow') . 'Genius!' . color('reset');
        return;
    }

    if ($percent >= 75) {
        say color('yellow on_red') . 'Magnificent!' . color('reset');
        return;
    }

    if ($percent >= 50) {
        say color('green on_white') . 'Impressive!' . color('reset');
        return;
    }

    if ($percent >= 35) {
        say color('blue on_white') . 'Splendid' . color('reset');
        return;
    }

    if ($percent >= 20) {
        say color('cyan on_white') . 'Great' . color('reset');
        return;
    }

    say color('bold') . 'Phew!' . color('reset');
}


sub console ($secret) {
    say "Sorry, but the secret word was " . color('bold black on_white') . $secret . color('reset');
}


sub chooseWordBySize ($dictionaryFile, $wordSize) {
    open(my $wordsFH, "<", $dictionaryFile) or die("cannot find words file at $dictionaryFile");

    my @candidates;
    while (my $word = readline($wordsFH)) {
        chomp ($word);
        next if length($word) != $wordSize;

        # ignore words with apostrophes and capital letters
        next if $word =~ /['A-Z]/;

        push @candidates, lc($word);
    }
    close $wordsFH;

    # This set of words will be needed later to validate guesses
    $gCandidateWords = \@candidates;

    return $candidates[ int(rand() * scalar(@candidates)) ];
}
