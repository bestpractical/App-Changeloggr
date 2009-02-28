package App::Changeloggr::View;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

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
    h1 { $changelog->name }
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

1;

