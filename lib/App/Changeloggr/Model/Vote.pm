use strict;
use warnings;

package App::Changeloggr::Model::Vote;
use Jifty::DBI::Schema;
use Scalar::Defer 'defer';

use App::Changeloggr::Record schema {
    column change =>
        refers_to App::Changeloggr::Model::Change,
        is protected;

    column user_session_id =>
        type is 'text',
        default is defer { Jifty->web->session->id },
        is private;

    column tag =>
        type is 'text';
};

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    # votes are not private except who submitted the vote
    return 1 if $right eq 'read' && $args{column} ne 'user_session_id';

    # anyone can vote
    return 1 if $right eq 'create';

    # but votes are immutable
    return $self->SUPER::current_user_can($right, %args);
}

1;

