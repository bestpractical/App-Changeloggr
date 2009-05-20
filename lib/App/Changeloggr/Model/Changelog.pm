use strict;
use warnings;

package App::Changeloggr::Model::Changelog;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column owner =>
        refers_to App::Changeloggr::Model::User,
        default is defer { Jifty->web->current_user->id },
        is protected,
        since '0.0.13';

    column name =>
        type is 'text',
        label is 'Project name',
        is distinct,
        is mandatory,
        ajax validates;

    column done =>
        is boolean,
        hints are 'This Changelog is no longer accepting Votes',
        default is 0;

    column admin_token =>
        type is 'text',
        is immutable,
        render as 'hidden',
        default is defer { _generate_admin_token() };

    column external_source =>
        type is 'text',
        render as 'text',
        label is 'Commit view',
        hints are 'The URL to view full commit info. __ID__ will be replaced with the commit ID.',
        since '0.0.3';

    column incremental_tags =>
        is boolean,
        default is 0,
        label is 'Incremental tags?',
        since '0.0.6';
};

# has to go below schema
use JiftyX::ModelHelpers;

sub validate_name {
    my $self = shift;
    my $name = shift;
    my $exist = M(Changelog => name => $name);
    return (0, "That name already exists -- choose another")
        if $exist->id && $exist->id != $self->id;
    return 1;
}

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
    my %args = @_;

    my $changes = M('ChangeCollection');
    $changes->create_from(
        changelog => $self,
        @_,
    );

    return $changes;
}

sub changes {
    my $self = shift;

    return M('ChangeCollection', changelog_id => $self);
}

sub tags {
    my $self = shift;

    return M('TagCollection', changelog_id => $self);
}

sub has_tag {
    my $self = shift;
    my $tag  = shift;

    my $tags = $self->tags;
    $tags->limit(column => 'text', value => $tag);
    return $tags->count;
}

sub add_tag {
    my $self = shift;
    my $text = shift;

    my $tag = M('Tag');
    $tag->as_superuser->create(
        text         => $text,
        changelog_id => $self->id,
    );
}

sub commit_links {
    my $self = shift;

    return M('CommitLinkCollection', changelog_id => $self);
}

sub unvoted_changes {
    my $self = shift;
    my $changes = M('ChangeCollection', changelog_id => $self);
    my $votes = $changes->join(
        type => 'left',
        column1 => 'id',
        table2 => 'votes',
        column2 => 'change_id',
        is_distinct => 1,
    );
    $changes->limit(
        leftjoin => $votes,
        column => 'user_id',
        value => $self->current_user->user_object->id,
        case_sensitive => 1,
    );
    $changes->limit(
        column => 'id',
        alias => $votes,
        operator => 'IS',
        value => 'NULL',
    );
    return $changes;
}

sub choose_change {
    my $self = shift;

    # This will become more advanced in the future, picking a change that
    # the current user has not voted on yet, ordered by the confidence of the
    # top tag. But for now.. an arbitrary change belonging to this changelog.
    my $changes = $self->unvoted_changes;
    $changes->rows_per_page(1);
    $changes->order_by( column => 'date', order => 'asc' );
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

