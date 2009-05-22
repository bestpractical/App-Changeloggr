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
        form_submit(label => 'Delete');
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
                            dt { $name }
                            dd { $code->() }
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

    if ($votes->count) {
        push @sections, [Comments => sub {
            ul {
                while (my $vote = <$votes>) {
                    li { $vote->comment }
                }
            }
        }];
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
            li { tt { 'git log --pretty=fuller --stat' }};
            li { tt { 'svn log' }};
            li { tt { 'svn log --xml' }};
        }
    };
}

sub edit_links {
    my $changelog = shift;
    my $links = $changelog->commit_links;

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

    form {
        if ($tags->count) {
            ul {
                while (my $tag = $tags->next) {
                    li {
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
                        $delete_tag->button(label => "Delete", class => "inline delete");
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

1;

