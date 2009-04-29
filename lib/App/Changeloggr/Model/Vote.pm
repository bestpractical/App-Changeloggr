use strict;
use warnings;

package App::Changeloggr::Model::Vote;
use Jifty::DBI::Schema;
use Scalar::Defer 'defer';

use App::Changeloggr::Record schema {
    column change_id =>
        refers_to App::Changeloggr::Model::Change,
        is mandatory,
        is immutable,
        render as 'hidden';

    column user_id =>
        refers_to App::Changeloggr::Model::User,
        is mandatory,
        is immutable,
        is private,
        default is defer { _default_user() };

    column tag =>
        type is 'text',
        is mandatory,
        is immutable;

    column comment =>
        type is 'text',
        default is '',
        since '0.0.3';
};

sub _default_user {
    my $session_id = Jifty->web->session->id;
    return if !defined($session_id);

    my $user = App::Changeloggr::Model::User->new;
    $user->load_or_create(session_id => $session_id);
    return $user;
}

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    # votes are public except who submitted the vote
    return 1 if $right eq 'read' && $args{column} ne 'user_id';

    # anyone can vote
    return 1 if $right eq 'create';

    # but votes are immutable
    return $self->SUPER::current_user_can($right, %args);
}

1;

