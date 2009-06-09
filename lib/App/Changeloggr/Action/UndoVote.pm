package App::Changeloggr::Action::UndoVote;
use strict;
use warnings;
use base 'Jifty::Action';

sub take_action {
    my $self = shift;
    my $user = Jifty->web->current_user->user_object;
    $user->undo_vote;
}

1;

