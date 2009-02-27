package App::Changeloggr::View;
use Jifty::View::Declare -base;
use strict;
use warnings;

template '/' => page {
    my $changelogs = App::Changeloggr::Model::ChangelogCollection->new;
    $changelogs->limit(column => 'done', value => 0);

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
    my $create = new_action('CreateChangelog');
    form {
        render_action $create, ['name'];
        form_submit(label => 'Create');
    };
};

template '/changelog' => page {
    my $changelog = get_changelog();
    h1 { $changelog->name }
};

template '/changelog/admin' => page {
    my $changelog = get_changelog();

    my $update = $changelog->as_update_action;
    form {
        render_action $update, ['name', 'done'];
        form_submit(label => 'Update');
    };
};

sub get_changelog {
    my $id = get 'id';

    my $changelog = App::Changeloggr::Model::Changelog->new;
    $changelog->load($id);

    return $changelog;
}

sub changelog_summary {
    my $changelog = shift;

    hyperlink(
        url   => '/changelog/' . $changelog->id,
        label => $changelog->name,
    );
}

1;

