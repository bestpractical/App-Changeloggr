use strict;
use warnings;

package App::Changeloggr::Model::Tag;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column changelog_id =>
        refers_to App::Changeloggr::Model::Changelog,
        is mandatory,
        is immutable,
        render as 'hidden';

    column text =>
        type is 'text',
        label is 'Tag',
        is mandatory,
        is immutable,
        ajax canonicalizes;

    column hotkey =>
        type is 'text',
        label is 'Hotkey',
        is case_sensitive,
        ajax validates,
        ajax canonicalizes;
};

sub validate_hotkey {
    my $self = shift;
    my $key = shift;
    my $args = shift || {};
    return 1 if not defined $key or not length $key;
    my $existing = App::Changeloggr::Model::TagCollection->new;
    $existing->limit( column => 'changelog_id', value => $args->{changelog_id} || $self->changelog->id );
    $existing->limit( column => 'hotkey',       value => $key );
    return (0, "Duplicate key!") if $existing->first and ($existing->first->id != ($self->id||0));
    return 1;
}

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # anyone can read a tag
    return 1 if $right eq 'read';

    return $self->SUPER::current_user_can($right, @_);
}


1;

