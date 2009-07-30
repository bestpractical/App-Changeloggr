package App::Changeloggr::View::Leaderboard;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

template '/global' => page {
    my $votes = M('VoteCollection');
    $votes->unlimit;
    show_leaderboard($votes);
};

template '/changelog' => page {
    my $changelog = Changelog(name => get('changelog'));
    show_leaderboard($changelog->votes);
};

sub show_leaderboard {
    my $votes = shift;

    $votes->group_by_voter;
    ol {
        for (0 .. 25) {
            my $vote = $votes->next
                or last;
            li {
                my $name = $vote->user->name || 'anonymous';
                outs _("%1 - %2", $name, $vote->id);
            }
        }
    }
}

1;

