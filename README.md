# wordle-terminal
A version of the popular Wordle game for the terminal along with a solver

## Summary

Please enjoy this recreation of the popular web browser game Wordle as
imagined for a UNIX Terminal in the late 80s (because, you know, color
fonts).

You will need a modern version of perl (5.20 or above) to play.

    
    ./wordle-play.pl

If you would like help with the game, you might like the solver
program.  It is used to narrow the scope of words:


    #              pattern  filter out these letters   require these letters
    ./wordle-solve .i...    stio                       rn

If you got a kick out of this avativistic tool, please drop me an
email.

Cheers.
    
## Author

Joe Johnston <jjohn@taskboy.com>
