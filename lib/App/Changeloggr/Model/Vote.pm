use strict;
use warnings;

package App::Changeloggr::Model::Vote;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column change =>
        refers_to App::Changeloggr::Model::Change;

    column user_session_id =>
        type is 'text';

    column tag =>
        type is 'text';
};

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    return 1 if $self->current_user->is_superuser;

    # voters are private..
    return 0 if $right eq 'read' && $args{column} eq 'user_session_id';

    # ..but votes are not
    return 1 if $right eq 'read';

    # anyone can vote
    return 1 if $right eq 'create';

    # but votes are immutable
    return 0;
}

1;

