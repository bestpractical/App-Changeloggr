package App::Changeloggr::View::Leaderboard;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

template '/global' => page {
    my $votes = M('VoteCollection');
    $votes->unlimit;
    title is 'Leaderboard';
    show_leaderboard($votes);
};

template '/changelog' => page {
    my $changelog = Changelog(name => get('changelog'));
    title is _('Leaderboard for %1', $changelog->name);
    show_leaderboard($changelog->votes);
};

sub show_leaderboard {
    my $votes = shift;

    $votes->limit_to_visible('tag');
    $votes->group_by_voter;

    ol {
        for (1 .. 25) {
            my $vote = $votes->next
                or last;
            my $is_current = $vote->user->id == Jifty->web->current_user->id;
            li {
                my $name = $vote->user->name || 'anonymous';
                outs_raw '<b>' if $is_current;
                outs _("%1: %2", $name, $vote->id);

                if ($is_current) {
                    outs_raw '</b>';
                    outs " -- That's you!";
                }
            }
        }
    }
}

1;

