#!/usr/bin/env perl
use Modern::Perl;

use FindBin;

sub main {
    my ($pattern, $exclude, $required) = @ARGV;

    if (!$pattern) {
        die("$0 [PATTERN] [EXCLUDE] [REQUIRED]");
    }

    if (length($pattern) != 5) {
        die("Pattern must be 5 characters\n");
    }

    $exclude //= "";
    $required //= "";
    my @required;
    if ($required) {
        @required = split //, $required;
    }

    my @searchOrder = (
                       "/usr/share/dict/words",
                       "$FindBin::Bin/5-letter-words.txt",
                      );

    my $dictionaryFile;
    for my $searchOrder (@searchOrder) {
        if (-e $searchOrder) {
            $dictionaryFile = $searchOrder;
            last;
        }
    }

    if (!-e $dictionaryFile) {
        die("Cannot find dictionary file.\n");
    }

    open my $wordsFH, "<", $dictionaryFile or die("words: $!");

    my %suggestions;
  NEXT_WORD:
    while (my $word = readline($wordsFH)) {
        chomp ($word);
        next NEXT_WORD if length($word) != 5;
        next NEXT_WORD if $word =~ /['A-Z]/;

        if ($word =~ /^$pattern$/i) {
            for my $r (@required) {
                if ($word !~ /$r/) {
                    next NEXT_WORD;
                }
            }

            if ($exclude) {
                if ($word =~ /[$exclude]/) {
                    next NEXT_WORD;
                }
            }

            for my $letter (split //, $word) {
                # Ignore the pattern, required and ignored letters
                if (index($pattern, $letter) > -1) {
                    next;
                }

                if ($exclude) {
                    next if index($exclude, $letter) > -1;
                }

                if (@required) {
                    next if grep { $letter eq $_ } @required;
                }

                $suggestions{$letter} //= 0; # being pedantic
                $suggestions{$letter} += 1;
            }
            print "$word\n";
        }
    }
    close $wordsFH;

    # show first 3 most common letters
    if (keys %suggestions) {
        print("\nThese are the top most common letters in the suggestions\n");
        my $shown = 0;
        for my $letter (sort { $suggestions{$b} <=> $suggestions{$a} } keys %suggestions) {
            printf("%s => %d\n", $letter, $suggestions{$letter});
            $shown += 1;
            last if $shown >= 3;
        }
    }
}

main();

