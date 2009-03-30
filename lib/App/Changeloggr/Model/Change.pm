use strict;
use warnings;

package App::Changeloggr::Model::Change;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column changelog =>
        refers_to App::Changeloggr::Model::Changelog,
        is mandatory,
        is immutable;

    column raw =>
        type is 'text',
        label is 'Raw',
        is mandatory,
        is immutable;

    column identifier =>
        type is 'text',
        label is 'Identifier',
        is mandatory;

    column author =>
        type is 'text',
        label is 'Author',
        is mandatory;

    column date =>
        type is 'timestamp',
        filters are qw( Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime),
        label is 'Date';

    column message =>
        type is 'text',
        label is 'Body',
        is mandatory;

    column diffstat =>
        type is 'text',
        label is 'Diff';
};

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # anyone can read a change
    return 1 if $right eq 'read';

    return $self->SUPER::current_user_can($right, @_);
}


1;

