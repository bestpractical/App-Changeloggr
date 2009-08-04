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

sub position_for {
    my $self      = shift;
    my $changelog = shift;

    my $session = Jifty::Web::Session->new;
    $session->load;

    my $key = "changelog-" . $changelog->id;
    my $position = $session->get($key);
    if (!defined($position)) {
        $position = $changelog->get_starting_position;
        # Don't set if we have no changes
        $self->set_position_for($changelog, $position) if defined $position;
    }

    return $position;
}

sub set_position_for {
    my $self      = shift;
    my $changelog = shift;
    my $position  = shift;

    my $session = Jifty::Web::Session->new;
    $session->load;

    my $key = "changelog-" . $changelog->id;
    $session->set($key => $position);
}

1;

