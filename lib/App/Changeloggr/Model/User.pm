use strict;
use warnings;

package App::Changeloggr::Model::User;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column name =>
        type is 'text',
        label is 'Name',
        is distinct;

    column session_id =>
        type is 'text',
        render as 'hidden',
        is immutable;
};

sub since { '0.0.4' }

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    # the current user can do anything to his account
    my $session_id = $self->__value('session_id');
    return 1 if $session_id eq (Jifty->web->session->id||'');

    # users are private except name
    return 1 if $right eq 'read' && $args{column} ne 'name';

    # anyone can create accounts
    return 1 if $right eq 'create';

    # but otherwise users are locked down
    return $self->SUPER::current_user_can($right, %args);
}

1;

