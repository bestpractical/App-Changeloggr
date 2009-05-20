use strict;
use warnings;

package App::Changeloggr::Model::CommitLink;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column changelog_id =>
        refers_to App::Changeloggr::Model::Changelog,
        is mandatory,
        is immutable,
        render as 'hidden';

    column find =>
        type is 'text',
        is mandatory
        label is 'Find',
        hints are 'Any valid regular expression';

    column href =>
        type is 'text',
        is mandatory,
        label is 'Link to',
        hints are 'Use $1, $2, etc to refer to capture groups';

};

use constant since => '0.0.2';

sub linkify {
    my $self = shift;
    my $text = shift;

    my $find = $self->find;
    $text =~ 
        s{($find)}{
            my @matches = map {substr($text,$-[$_], $+[$_] - $-[$_])} 1..$#+;
            my $href = $self->href;
            $href =~ s{\$(\d+)}{$matches[$1]}eg;
            qq{<a href="$href">$matches[0]</a>}
        }eg;
    return $text;
}

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # anyone can read
    return 1 if $right eq 'read';

    return $self->SUPER::current_user_can($right, @_);
}

1;

