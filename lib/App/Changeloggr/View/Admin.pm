package App::Changeloggr::View::Admin;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

template '/create-changelog' => page {
    my $create = new_action('CreateChangelog', moniker => 'create-changelog');
    form {
        render_action $create, ['name'];
        form_next_page url => '/admin/created-changelog';
        form_submit(label => 'Create');
    };
};

template '/changelog' => page {
    my $changelog = Changelog(id => get('id'));

    my $update = $changelog->as_update_action;
    form {
        render_action($update);
        form_submit(label => 'Update');
    };

    add_changes_to($changelog);

    edit_links($changelog);

    edit_tags($changelog);

    my $delete = $changelog->as_delete_action;
    form {
        render_action($delete);
        form_next_page(url => '/');
        form_submit(label => 'Delete');
    };
};

sub add_changes_to {
    my $changelog = shift;

    if ($changelog->changes->count) {
        p { _("This changelog has %quant(%1,change).", $changelog->changes->count) }
    }

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

sub edit_links {
    my $changelog = shift;
    my $links = $changelog->commit_links;

    while (my $link = $links->next) {
        form {
            my $delete_link = $link->as_delete_action;
            render_action $delete_link;
            form_submit(label => $link->find . " => " . $link->href);
        }
    }

    form {
        my $add_link = new_action(
            class     => "CreateCommitLink",
            arguments => { changelog_id => $changelog->id }
        );
        render_action $add_link;
        form_submit(label => 'Add Link');
    }
}

sub edit_tags {
    my $changelog = shift;
    my $tags = M("TagCollection", changelog_id => $changelog);

    while (my $tag = $tags->next) {
        form {
            my $delete_tag = $tag->as_delete_action;
            render_action $delete_tag;
            form_submit(label => $tag->text);
        }
    }

    form {
        my $add_tag = new_action(
            class     => "CreateTag",
            arguments => { changelog_id => $changelog->id }
        );
        render_action $add_tag;
        form_submit(label => 'Add Tag');
    }
}

1;

