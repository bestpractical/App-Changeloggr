use strict;
use warnings;

package App::Changeloggr::Model::User;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column name =>
        type is 'text',
        label is 'Name',
        is distinct;

    column session_id =>
        type is 'text',
        render as 'hidden',
        is immutable;

    column show_details =>
        is boolean,
        default is 0,
        label is 'Always show details',
        since '0.0.9',
        till '0.0.11';

    column show_diff =>
        is boolean,
        default is 0,
        label is 'Always show full diff',
        since '0.0.10';

    column strip_diff_anchor =>
        is boolean,
        default is 0,
        label is 'Strip full diff anchor',
        since '0.0.17';

    column access_level =>
        is mandatory,
        default is 'guest',
        since '0.0.12',
        label is 'Access level',
        valid_values are qw(user staff),
        is protected;

};

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

# XXX TODO, merging params should 'just work' but does not
__PACKAGE__->column('email')->writable(1);

# has to go below schema
use JiftyX::ModelHelpers;

sub since { '0.0.4' }

sub current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    # the current user can do anything to his account
    my $session_id = $self->__value('session_id');
    return 1 if $session_id
             && $session_id eq (Jifty->web->session->id||'');

    # users are private except name
    return 1 if $right eq 'read' and ( $args{column} eq 'name' or $args{column} eq 'access_level' );

    # anyone can create accounts
    return 1 if $right eq 'create';

    # but otherwise users are locked down
    return $self->SUPER::current_user_can($right, %args);
}

sub votes {
    my $self = shift;

    return M('VoteCollection', user_id => $self->id);
}

sub vote_placement {
    my $self = shift;
    my $votes = $self->votes->limit_to_visible('tag')->count;
    my $place = Jifty->handle->simple_query(<<"EOSQL")->fetch->[0];
select count(*)
  from (select user_id
          from votes
         where votes.tag not like E'\\\\_%'
         group by votes.user_id
        having count(*) >= $votes) as v;
EOSQL
    $place++ unless $votes;
    return ($votes, $place);
}

sub undo_vote {
    my $self = shift;
    my $votes = $self->votes;
    $votes->order_by(
        column => 'id',
        order  => 'DESC',
    );
    $votes->set_page_info(
        current_page => 1,
        per_page     => 1,
    );

    my $vote = $votes->first;

    if (!$vote) {
        return (0, "No vote to delete");
    }

    return $vote->delete;
}

1;

