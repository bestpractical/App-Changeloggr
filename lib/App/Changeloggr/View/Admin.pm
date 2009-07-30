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
    my $changelog = Changelog(id => get('id'))->as_superuser;

    my $update = $changelog->as_update_action;
    form {
        render_action($update);
        form_submit(label => 'Update');
    };

    my $delete = $changelog->as_delete_action;
    form {
        render_action($delete);
        form_next_page(url => '/');
        form_submit(
            label   => 'Delete',
            onclick => q{return confirm('Really delete this changelog?');},
        );
    };
};

template '/changelog/changes' => page {
    my $changelog = Changelog(id => get('id'));
    add_changes_to($changelog);
};

template '/changelog/tags' => page {
    my $changelog = Changelog(id => get('id'));
    edit_tags($changelog);
};

template '/changelog/links' => page {
    my $changelog = Changelog(id => get('id'));
    edit_links($changelog);
};

template '/changelog/votes' => page {
    my $changelog = Changelog(id => get('id'));
    my $changes = $changelog->changes;

    h3 { "Changes" }
    ul {
        for my $change (@$changes) {
            li {
                my $message = $change->message;
                substr($message, 40) = '...' if length($message) >= 40;

                span { $message };

                my @sections = change_sections($change);
                if (@sections) {
                    dl {
                        for (@sections) {
                            my ($name, $code) = @$_;
                            dt { {class is lc $name }; $name }
                            dd { {class is lc $name }; $code->() }
                        }
                    }
                }
            }
        }
    };

};


sub change_sections {
    my $change = shift;
    my @sections;

    my $votes = $change->votes;
    $votes->limit_to_commented;
    if ( $votes->count ) {
        push @sections, [
            Comments => sub {
                ul {
                    while ( my $vote = <$votes> ) {
                        li { $vote->comment };
                    }
                };
            }
        ];
    }

    $votes = $change->grouped_votes;
    if ( $votes->count ) {
        push @sections, [
            Votes => sub {
                dl {
                    while ( my $vote = <$votes> ) {
                        dt { $vote->tag };
                        dd { $vote->id };
                    }
                };
            }
        ];
    }

    return @sections;
}

template '/changelog/changes/count' => sub {
    my $id = get('id');
    my $changelog = M('Changelog', id => $id);
    if ($changelog->changes->count) {
        p { _("This changelog has %quant(%1,change).", $changelog->changes->count) }
    }

    if (Jifty->config->app('BackgroundImport')) {
        Jifty->subs->update_on(
            class   => 'AddChanges',
            queries => [{ id => $id }],
        );
    }
};

sub add_changes_to {
    my $changelog = shift;

    render_region(
        name => 'count',
        path => '/admin/changelog/changes/count/'.$changelog->as_superuser->admin_token,
    );

    my $add_changes = new_action('AddChanges');
    form {
        render_action($add_changes => ['changes']);

        render_param($add_changes => admin_token => (
            default_value => $changelog->as_superuser->admin_token,
            render_as     => 'hidden',
        ));

        form_submit(label => 'Upload');
    };

    p {
        outs 'We accept the following log formats.';
        ul {
            li { tt { 'git log --pretty=fuller --stat --reverse' }};
            li { tt { 'svn log' }};
            li { tt { 'svn log --xml' }};
        }
    };
}

sub edit_links {
    my $changelog = shift;
    my $links = $changelog->commit_links;

    p {
        { class is "admin docs" };
        outs_raw <<'EOT';

<em>Links</em> allow you to hyperlink changelog bodies to arbitrary
locations.  <b>Find</b> should be an arbitrary regular expression to
search for in the changelog body -- note that this expression is
applied after HTML entity escaping has occurred.  The <b>Link to</b>
field is the URL that matching portions of the body will be inked to.
If the <b>Find</b> expression had capture groups (created by parens),
these will be available in the <b>Link to</b> field as $1, $2, and so
forth.

EOT
    };

    form {
        if ($links->count) {
            ul {
                while (my $link = $links->next) {
                    li {
                        my $delete_link = $link->as_delete_action;
                        render_action $delete_link;
                        tt { $link->find };
                        outs_raw "<br /> &rArr; ";
                        tt { $link->href };
                        $delete_link->button(label => "Delete");
                    }
                }
            }
        }

        my $add_link = new_action(
            class     => "CreateCommitLink",
            arguments => { changelog_id => $changelog->id }
        );
        render_action $add_link;
        form_submit(label => 'Add Link', submit => [$add_link]);
    }
}

sub edit_tags {
    my $changelog = shift;
    my $tags = $changelog->visible_tags;

    p {
        { class is "admin docs" };
        outs_raw <<'EOT';

<em>Tags</em> are the primary way in which changelogs are categorized.
Each user votes for up to one tag per change; these votes are tallied
and used to assign changes to tags when the changelog is downloaded.

EOT
    };

    form {
        if ($tags->count) {
            ul {
                while (my $tag = $tags->next) {
                    li {
                        display_tag($tag);
                    }
                }
            }
        }

        my $add_tag = new_action(
            class     => "CreateTag",
            arguments => { changelog_id => $changelog->id }
        );
        render_action $add_tag;
        form_submit(label => 'Add Tag', submit => [$add_tag]);
    }
}

sub display_tag {
    my $tag = shift;
    my $changelog = $tag->changelog;

    render_region(
        path => '/admin/changelog/tag/display/' . $changelog->admin_token,
        name => 'tag_' . $tag->id,
        arguments => {
            tag => $tag->id,
        },
    );

}

template '/changelog/tag/display' => sub {
    my $tag_id = get('tag');
    my $tag = Tag($tag_id);

    my $changelog = $tag->changelog;

    my $delete_tag = $tag->as_delete_action;
    render_action $delete_tag;
    outs $tag->text;
    if ($tag->hotkey) {
        outs " ";
        span {
            { class is "hotkey" };
            "(hotkey: ".$tag->hotkey.")"
        }
    }

    hyperlink(
        label => _('Edit'),
        as_button => 1,
        onclick => {
            replace_with => '/admin/changelog/tag/edit/' . $changelog->admin_token,
        },
    );

    $delete_tag->button(label => "Delete", class => "inline delete");

    my $tooltip = $tag->tooltip;
    my $description = $tag->description;

    if ($tooltip || $description) {
        dl {
            if ($tooltip) {
                dt { "Tooltip" }
                dd { $tooltip  }
            }
            if ($description) {
                dt { "Description" }
                dd { $description  }
            }
        }
    }
};

template '/changelog/tag/edit' => sub {
    my $tag_id = get('tag');
    my $tag = Tag($tag_id);
    my $changelog = $tag->changelog;

    my $update_tag = $tag->as_update_action;
    render_action $update_tag;

    $update_tag->button(
        label => "Save",
        class => "inline update",
        onclick => {
            submit       => $update_tag,
            replace_with => '/admin/changelog/tag/display/' . $changelog->admin_token,
        },
    );

    hyperlink(
        label => "Cancel",
        class => "inline cancel",
        as_button => 1,
        onclick => {
            replace_with => '/admin/changelog/tag/display/' . $changelog->admin_token,
        },
    );
};

1;

