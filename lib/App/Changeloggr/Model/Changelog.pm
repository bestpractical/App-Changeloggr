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
        render as 'hidden',
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

    # anyone can create and read changelogs (except admin token)
    return 1 if $right eq 'create'
             || ($right eq 'read' && $args{column} ne 'admin_token');

    # but not delete or update. those must happen as root
    return $self->SUPER::current_user_can($right, %args);
}

sub parse_and_add_changes {
    my $self = shift;
    my $text = shift;

    my $changes = App::Changeloggr::Model::ChangesCollection->create_from_text(
        text      => $text,
        changelog => $self,
    );

    return $changes;
}

1;

