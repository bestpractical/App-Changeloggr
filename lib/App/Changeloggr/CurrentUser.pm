package App::Changeloggr::CurrentUser;
use strict;
use warnings;
use base 'Jifty::CurrentUser';

sub user_object {
    my $session = Jifty->web->session
        or return;
    my $user = App::Changeloggr::Model::User->new;
    $user->load_or_create(session_id => $session);
    return $user;
}

1;

