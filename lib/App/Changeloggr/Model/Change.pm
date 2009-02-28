use strict;
use warnings;

package App::Changeloggr::Model::Change;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column changelog =>
        refers_to App::Changeloggr::Model::Changelog;

    column identifier =>
        type is 'text',
        label is 'Identifier';

    column author =>
        type is 'text',
        label is 'Author';

    column date =>
        type is 'text',
        label is 'Date';

    column message =>
        type is 'text',
        label is 'Body';

    column diff =>
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

sub guess_type {
    my $self = shift;
    my $text = shift;

    if ($text =~ /^commit [0-9a-f]{32}$/m) {
        return 'git';
    }

    if ($text =~ /^-{70}$/m) {
        return 'svk';
    }

    if ($text =~ /^\w{3} \w{3} +\d+ \d\d:\d\d:\d\d \w{3} \d{4}  /m) {
        return 'darcs';
    }

    return 'unknown';
}

1;

