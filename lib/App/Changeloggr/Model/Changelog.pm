use strict;
use warnings;

package App::Changeloggr::Model::Changelog;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column name =>
        type is 'text',
        label is 'Project name',
        is distinct;

    column done =>
        is boolean,
        default is 0;

    column admin_token =>
        type is 'text',
        is immutable,
        default is defer { _generate_admin_token() };
};

sub _generate_admin_token {
    require Data::GUID;
    Data::GUID->new->as_string;
}

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    return 1 if $self->current_user->is_superuser;

    # admin tokens are private
    return 0 if $right eq 'read' && $args{column} eq 'admin_token';

    # anyone can create and read changelogs
    return 1 if $right eq 'create' || $right eq 'read';

    # but not delete or update. those must happen as root
    return 0;
}

1;

