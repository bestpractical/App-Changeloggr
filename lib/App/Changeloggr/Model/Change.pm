use strict;
use warnings;

package App::Changeloggr::Model::Change;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column changelog_id =>
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

sub grouped_votes {
    my $self = shift;
    my $votes = App::Changeloggr::Model::VoteCollection->new;
    $votes->limit( column => 'change_id', value => $self->id );
    $votes->column(
        column => 'tag',
    );
    $votes->group_by(
        column => 'tag',
    );
    $votes->order_by(
        function => 'count(*)',
        order => 'desc',
    );
    return $votes;
}

1;

