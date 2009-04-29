package App::Changeloggr::View::Account;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

template '/index.html' => page {
    my $user = Jifty->web->current_user->user_object;
    my $update = $user->as_update_action;

    render_action($update);

    form_submit(
        label   => 'Update',
        onclick => { submit => $update },
    );
};

template '/votes' => page {
};

1;

