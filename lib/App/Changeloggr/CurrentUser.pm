package App::Changeloggr::CurrentUser;
use strict;
use warnings;
use base 'Jifty::CurrentUser';

sub is_staff {
    my $self = shift;

    my $user = $self->user_object
        or return 0;

    return $user->access_level eq 'staff';
}

1;

