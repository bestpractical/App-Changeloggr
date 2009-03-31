use strict;
use warnings;

package App::Changeloggr::Model::Tag;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column changelog =>
        refers_to App::Changeloggr::Model::Changelog,
        is mandatory,
        is immutable;

    column text =>
        type is 'text',
        label is 'Raw',
        is mandatory,
        is immutable;
};

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # anyone can read a tag
    return 1 if $right eq 'read';

    return $self->SUPER::current_user_can($right, @_);
}


1;

