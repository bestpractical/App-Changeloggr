package App::Changeloggr::View;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

# No salutation, ever
template '/salutation' => sub {};

template '/' => page {
    my $changelogs = M(ChangelogCollection => done => 0);
    $changelogs->with_changes;

    if ($changelogs->count) {
        h2 { "These projects need your help!" };
        ul {
            while (my $changelog = $changelogs->next) {
                li { changelog_summary($changelog) }
            }
        }
    } else {
        redirect '/create-changelog';
    }
};

template '/create-changelog' => page {
    my $create = new_action('CreateChangelog', moniker => 'create-changelog');
    form {
        render_action $create, ['name'];
        form_next_page url => '/created-changelog';
        form_submit(label => 'Create');
    };
};

template '/changelog' => page {
    my $changelog = Changelog(name => get('name'));

    h1 { $changelog->name };

    render_region(
        name => 'vote-on-change',
        path => '/vote-on-change',
        defaults => {
            changelog => $changelog->id,
        },
    );
};

template '/vote-on-change' => sub {
    my $changelog = M('Changelog', id => get('changelog'));
    my $change = $changelog->choose_change;
    if ($change) {
        show_change($change);
        show_vote_form($change);
    } else {
        h2 { "No changes left in this log" };
    }
};

template '/changelog/admin' => page {
    my $changelog = Changelog(id => get('id'));

    my $update = $changelog->as_update_action;
    form {
        render_action($update);
        form_submit(label => 'Update');
    };

    add_changes_to($changelog);

    my $delete = $changelog->as_delete_action;
    form {
        render_action($delete);
        form_next_page(url => '/');
        form_submit(label => 'Delete');
    };
};

sub add_changes_to {
    my $changelog = shift;

    my $add_changes = new_action('AddChanges');

    form {
        render_action($add_changes => ['changes']);

        render_param($add_changes => admin_token => (
            default_value => $changelog->as_superuser->admin_token,
            render_as     => 'hidden',
        ));

        form_submit(label => 'Add');
    };
}

sub changelog_summary {
    my $changelog = shift;

    hyperlink(
        url   => '/changelog/' . $changelog->name,
        label => $changelog->name,
    );
}

sub show_change {
    my $change = shift;

    h3 { $change->message }
}

sub show_vote_form {
    my $change = shift;

    form {
        my $vote = new_action(
            class     => "CreateVote",
            arguments => { change => $change->id }
        );
        render_action $vote ;
        form_submit(
            label   => 'Vote',
            onclick => { submit => $vote, refresh_self => 1 }
        );
    }
}

1;

