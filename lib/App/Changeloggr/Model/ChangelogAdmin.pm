use strict;
use warnings;

package App::Changeloggr::Model::ChangelogAdmin;
use Jifty::DBI::Schema;
use Scalar::Defer 'defer';

use App::Changeloggr::Record schema {
    column changelog_id =>
        refers_to App::Changeloggr::Model::Changelog,
        is mandatory,
        is immutable;

    column user_id =>
        refers_to App::Changeloggr::Model::User,
        is mandatory,
        is immutable,
        default is defer { Jifty->web->current_user->user_object };
};

sub since { '0.0.14' }

sub current_user_can {
    my $self = shift;

    # Only superuser can CRUD these records
    return $self->current_user->is_superuser;
}

