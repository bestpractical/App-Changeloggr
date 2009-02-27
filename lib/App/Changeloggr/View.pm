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

sub changelog_summary {
    my $changelog = shift;

    hyperlink(
        url   => '/changelog/' . $changelog->id,
        label => $changelog->name,
    );
}

1;

