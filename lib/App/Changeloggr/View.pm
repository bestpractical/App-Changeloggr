package App::Changeloggr::View;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

template '/' => page {
    my $changelogs = M(ChangelogCollection => done => 0);

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
        render_action $update, ['name', 'done'];
        form_submit(label => 'Update');
    };
};

sub changelog_summary {
    my $changelog = shift;

    hyperlink(
        url   => '/changelog/' . $changelog->id,
        label => $changelog->name,
    );
}

1;

