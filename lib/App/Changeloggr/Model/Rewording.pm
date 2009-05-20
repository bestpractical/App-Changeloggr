use strict;
use warnings;

package App::Changeloggr::Model::Rewording;
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

    column message =>
        type is 'text',
        render as 'textarea',
        default is '';

    column date =>
        type is 'timestamp',
        filters are qw( Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime),
        label is 'Date',
        default is defer { DateTime->now };
};

sub since { '0.0.7' }

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    # rewordings are public
    return 1 if $right eq 'read' || $right eq 'create';

    # but are otherwise immutable
    return $self->SUPER::current_user_can($right, %args);
}

1;


