use strict;
use warnings;

package App::Changeloggr::Model::Changelog;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column name =>
        type is 'text',
        label is 'Project name',
        is distinct,
        is mandatory;

    column done =>
        is boolean,
        default is 0;

    column admin_token =>
        type is 'text',
        is immutable,
        render as 'hidden',
        default is defer { _generate_admin_token() };
};

# has to go below schema
use JiftyX::ModelHelpers;

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
             || ($right eq 'read' && ($args{column}||'') ne 'admin_token');

    # but not delete or update. those must happen as root
    return $self->SUPER::current_user_can($right, %args);
}

sub add_changes {
    my $self = shift;
    my $arg = shift;

    my $changes = M('ChangeCollection');
    if (ref $arg) {
        $changes->create_from_parser(
            parser    => $arg,
            changelog => $self,
        );
    } else {
        $changes->create_from_text(
            text      => $arg,
            changelog => $self,
        );
    }
    

    return $changes;
}

sub changes {
    my $self = shift;

    return M('ChangeCollection', changelog => $self);
}

sub choose_change {
    my $self = shift;

    # This will become more advanced in the future, picking a change that
    # the current user has not voted on yet, ordered by the confidence of the
    # top tag. But for now.. an arbitrary change belonging to this changelog.
    my $changes = M('ChangeCollection', changelog => $self);
    my $votes = $changes->join(
        type => 'left',
        column1 => 'id',
        table2 => 'votes',
        column2 => 'change',
        is_distinct => 1,
    );
    $changes->limit(
        leftjoin => $votes,
        column => 'user_session_id',
        value => Jifty->web->session->id,
        case_sensitive => 1,
    );
    $changes->limit(
        column => 'id',
        alias => $votes,
        operator => 'IS',
        value => 'NULL',
    );
    $changes->rows_per_page(1);
    return $changes->first;
}

sub generate {
    my $self = shift;
    my $format = Jifty->app_class( OutputFormat => shift || "Jifty" );
    Jifty::Util->require( $format )
          or return "";

    my $changes = $self->changes;
    $changes->order_by(column => 'date');
    my %categories;
    while (my $change = $changes->next) {
        my $votes = $change->grouped_votes;
        if (my $winner = $votes->first) {
            push @{$categories{$winner->tag}}, $change;
        } else {
            push @{$categories{unknown}}, $change;
        }
    }

    return $format->generate( changelog => $self, categories => \%categories );
}

1;

