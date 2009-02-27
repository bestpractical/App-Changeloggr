use strict;
use warnings;

package App::Changeloggr::Model::Changelog;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column name =>
        type is 'text',
        label is 'Project name';

    column done =>
        is boolean,
        default is 0;
};

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    return 1 if $self->current_user->is_superuser;

    # anyone can create and read changelogs
    return 1 if $right eq 'create' || $right eq 'read';

    # but not delete or update. those must happen as root
    return 0;
}

1;

