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

sub votes {
    my $self = shift;
    my $votes = App::Changeloggr::Model::VoteCollection->new;
    $votes->limit( column => 'change_id', value => $self->id );
    return $votes;
}

sub grouped_votes {
    my $self = shift;
    my $votes = $self->votes;

    $votes->limit_to_visible('tag');
    $votes->column(
        column => 'tag',
    );
    $votes->column(
        column => 'id',
        function => 'count(*)',
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

sub external_source {
    my $self = shift;
    my $url = $self->changelog->external_source;
    return unless $url;
    $url .= $self->identifier unless $url =~ s/__ID__/$self->identifier/ge;
    return $url;
}

sub importance_votes {
    my $self = shift;
    my $importance_votes = App::Changeloggr::Model::ImportanceCollection->new;
    $importance_votes->limit( column => 'change_id', value => $self->id );
    return $importance_votes;
}

sub numeric_importance {
    my $self = shift;
    my $importance_votes = $self->importance_votes;

    $importance_votes->column(
        column => 'importance',
    );
    $importance_votes->column(
        column   => 'id',
        function => 'count',
    );
    $importance_votes->group_by(
        column => 'importance',
    );

    my $numeric_importance = 0;

    while (my $importance_vote = <$importance_votes>) {
        my $importance = $importance_vote->importance;
        my $count = $importance_vote->id;

        $numeric_importance += $count if $importance eq 'major';
        $numeric_importance -= $count if $importance eq 'minor';
    }

    return $numeric_importance;
}

# This will order the tags for this change by the frequency that people have
# voted on this change with each tag. If ten people vote a tag "documentation"
# then that will show up before a tag "performance" that one joker voted.
sub prioritized_tags {
    my $self = shift;
    my $tags = $self->changelog->visible_tags;

    my $votes = $tags->join(
        type        => 'left',
        column1     => 'text',
        table2      => 'votes',
        column2     => 'tag',
        is_distinct => 1,
    );
    $tags->limit(
        leftjoin => $votes,
        column   => 'change_id',
        value    => $self->id,
    );

    # In order to pull out these columns, we need to group by it in Postgres
    $tags->group_by(
        function => 'main.id,main.changelog_id,main.text,main.hotkey,main.tooltip,main.description',
    );
    $tags->order_by(
        function => "count($votes.tag)",
        order    => 'DESC',
    );

    return $tags;
}

sub count_of_tag {
    my $self = shift;
    my $tag  = shift;

    my $text = ref($tag) ? $tag->text : $tag;

    my $votes = $self->votes;
    $votes->limit(
        column   => 'tag',
        operator => '=',
        value    => $text,
    );

    $votes->column(
        column   => 'id',
        function => 'count(main.tag)',
    );
    $votes->order_by({});

    return $votes->first->id;
}

1;

