use strict;
use warnings;

package App::Changeloggr::Model::Importance;
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
        default is defer { Jifty->web->current_user->user_object };

    column importance =>
        type is 'text',
        valid_values are qw(major normal minor),
        default is 'normal',
        is immutable;

    column date =>
        type is 'timestamp',
        filters are qw( Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime),
        label is 'Date',
        default is defer { DateTime->now };
};

sub since { '0.0.8' }

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    # importance-votes are public except for who the voter was
    return 1 if $right eq 'read' && $args{column} ne 'user_id';

    # anyone can submit importance-votes
    return 1 if $right eq 'create';

    # but importance-votes are immutable
    return $self->SUPER::current_user_can($right, %args);
}

1;

