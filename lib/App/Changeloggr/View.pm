package App::Changeloggr::View;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

require App::Changeloggr::View::Admin;
alias App::Changeloggr::View::Admin under '/admin';

require App::Changeloggr::View::Account;
alias App::Changeloggr::View::Account under '/account';

require Jifty::Plugin::SiteNews::View::News;
alias Jifty::Plugin::SiteNews::View::News under '/news';

# No salutation, ever
template '/salutation' => sub {};

# *We'll* put the keybindings div into the page.
template '/_elements/keybindings' => sub {};

template '/' => page {
    my $changelogs = M(ChangelogCollection => done => 0);
    $changelogs->with_changes;

    my $count = $changelogs->count;

    redirect '/admin/create-changelog' if $count == 0;

    h2 { "These projects need your help!" };
    ul {
        while (my $changelog = $changelogs->next) {
            li { changelog_summary($changelog) }
        }
    };
    h2 { "Recent news" };
    render_region(
        name => 'news',
        path => '/news/list',
    );
};

template '/changelog' => page {
    my $changelog = Changelog(name => get('name'));

    title is $changelog->name;

    render_region(
        name => 'vote-on-change',
        path => '/vote-on-change',
        defaults => {
            changelog => $changelog->id,
        },
    );

    show '/feedback/request_feedback';
};

template '/changelog/download' => sub {
    my $changelog = Changelog( name => get('name') );
    Jifty->handler->apache->header_out( 'Content-Type' => 'text/plain' );
    outs_raw( $changelog->generate( get('format') ) );
};

template '/vote-on-change' => sub {
    my $changelog = M('Changelog', id => get('changelog'));
    my $change = $changelog->choose_change;
    if ($change) {
        show_change($change, voting_form => 1);
    } else {
        my $has_changes = $changelog->changes->count;
        h2 { "No changes " . ($has_changes ? "left " : "") . " in this log" };
        p { "Thank you for all your votes!" } if $has_changes;
    }
};

sub changelog_summary {
    my $changelog = shift;

    hyperlink(
        url   => '/changelog/' . $changelog->name,
        label => $changelog->name,
    );

    if ($changelog->current_user_is_admin) {
        span {};
        my $admin_token = $changelog->as_superuser->admin_token;
        hyperlink(
            url => "/admin/changelog/$admin_token",
            label => "[administrate]",
        );
    }
}

sub show_change {
    my $change = shift;
    my %args = @_;

    div { id is 'keybindings' };

    div {
        { class is "change" };

        p {
            { class is "identifier" };
            if (my $url = $change->external_source) {
                hyperlink(
                    label  => $change->identifier,
                    url    => $url,
                    target => "diff",
                    class  => "external_source",
                );
            }
            else {
                outs $change->identifier;
            }
            span {
                "(". $change->changelog->unvoted_changes->count . " remaining)"
            }
        };

        p {
            { class is "change_message" };
            my $message = Jifty->web->escape($change->message);
            $message =~ s{\n}{<br />}g;
            my $links = $change->changelog->commit_links;
            $message = $_->linkify($message) while $_ = $links->next;
            outs_raw( $message );
        };

        ul {
            { class is "change_metadata" };
            li { "Author: " . $change->author };
            li { "Date: " . $change->date };
        };

        my $id = $change->id;
        render_region(
            name      => "change_$id",
            path      => '/change/more',
            arguments => {
                change => $id,
            },
        );

        if (my $url = $change->external_source) {
            if (Jifty->web->current_user->user_object->show_diff) {
                div {
                    render_region(
                        name => "change_${id}_source",
                        path => "/change/external_source",
                        arguments => {
                            url => $url,
                        },
                    );
                };
            }
            else {
                hyperlink(
                    label => 'Full diff',
                    class => 'external_source',
                    onclick => [{
                        region       => Jifty->web->qualified_region("change_${id}_source"),
                        replace_with => '/change/external_source',
                        toggle       => 1,
                        effect       => 'slideDown',
                        arguments    => {
                            url => $url,
                        },
                    },
                    "this.innerHTML = this.innerHTML == 'Full diff' ? 'Hide diff' : 'Full diff';",
                ]);
                div {
                    render_region("change_${id}_source");
                };
            }
        }

        if ($args{voting_form}) {
            hr {};
            show_vote_form($change);
            hr {};
            show_rewording_form($change);
        }
    };
}

template '/change/external_source' => sub {
    my $url = get('url');

    iframe {
        class is 'external_source';
        src is $url;
    };
};

template '/change/more' => sub {
    my $change = M('Change', id => get('change'));

    pre {
        my $diffstat = Jifty->web->escape($change->diffstat);

        for (['+', 'diffadd'], ['-', 'diffsub']) {
            my ($char, $class) = @$_;

            # this regex avoids coloring the symbols in filenames
            $diffstat =~ s{(\|\s+\d+ |</span>)(\Q$char\E+)}
                          {$1<span class="$class">$2</span>}g;
        }

        outs_raw $diffstat;
    };
};

sub show_vote_form {
    my $change = shift;

    my $changelog = $change->changelog;
    my $valid_tags = $change->prioritized_tags;

    form {
        h4 { 'Vote!' };
        my $vote = new_action(
            class     => "CreateVote",
            arguments => { change_id => $change->id }
        );

        render_param($vote, 'change_id');
        if ($valid_tags->count == 0 || $changelog->incremental_tags) {
            render_param($vote, 'tag');

            my $label = $changelog->incremental_tags ? 'Vote and add tag' : 'Vote';
            form_submit(
                label   => $label,
                onclick => { submit => $vote, refresh_self => 1 }
            );
        }

        if ($valid_tags->count) {
            my $tag_number = 0;
            my $voted_cusp = 0;
            while (my $valid_tag = $valid_tags->next) {
                my $label;
                my $count = $change->count_of_tag($valid_tag);

                # This is actually checking count+1, not id. It's count+1
                # because id 0 (aka count 0) records are not loaded. :/
                ++$tag_number;
                if ($count > 0) {
                    $label = _('%1 (%2)', $valid_tag->text, $count);
                }
                else {
                    $label = $valid_tag->text;

                    # Add a newline between tags that have been selected for
                    # this change and tags that haven't
                    if (!$voted_cusp) {
                        $voted_cusp = 1;
                        br {} unless $tag_number == 1;
                    }
                }

                $vote->button(
                    class       => "vote",
                    label       => $label,
                    key_binding => $valid_tag->hotkey,
                    onclick     => { submit => $vote, refresh_self => 1 },
                    arguments   => { tag => $valid_tag->text },
                );
            }
        }
        hr {};
        $vote->button(
            class       => "vote",
            label       => 'Skip this change',
            onclick     => { submit => $vote, refresh_self => 1 },
            arguments   => { tag => '_skip' },
        );
    }
}

sub show_rewording_form {
    my $change = shift;

    render_region(
        name => 'rewording',
        path => '/change/reword',
        arguments => {
            change => $change->id,
        },
    );
}

template '/change/reword' => sub {
    my $change_id = get('change');
    my $change = Change($change_id);

    my $rewording = Rewording(
        change_id => $change_id,
        user_id => Jifty->web->current_user->id,
    );
    if ($rewording->id) {
        p { "You submitted the following rewording:" };
        pre { $rewording->message };
    }
    else {
        my $create_rewording = new_action('CreateRewording');

        p { "Do you want to improve the content or wording of this change's message?" };

        render_hidden $create_rewording => 'change_id' => $change_id;
        render_param $create_rewording => (
            'message',
            label => '',
            default_value => $change->message,
        );

        $create_rewording->button(
            label => 'Reword',
            onclick => {
                submit => $create_rewording,
                refresh_self => 1,
            },
        );
    }
};

sub show_vote_comments {
    my $change = shift;
    my $votes = $change->votes;

    $votes->limit_to_commented;

    return if $votes->count == 0;

    h5 { "Comments" }
    ul {
        while (my $vote = <$votes>) {
            li { $vote->comment };
        }
    }
}

1;

