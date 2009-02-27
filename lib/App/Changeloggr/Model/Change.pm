use strict;
use warnings;

package App::Changeloggr::Model::Change;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column changelog =>
        refers_to App::Changeloggr::Model::Changelog;

    column author =>
        type is 'text',
        label is 'Author';

    column body =>
        type is 'text',
        label is 'Body';

    column diff =>
        type is 'text',
        label is 'Diff';
};

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    return 1 if $self->current_user->is_superuser;

    return 1 if $right eq 'read';

    # no ordinary users can update, delete, or create new changes
    return 0;
}

1;

