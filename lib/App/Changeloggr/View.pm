package App::Changeloggr::View;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

require App::Changeloggr::View::Admin;
alias App::Changeloggr::View::Admin under '/admin';

require App::Changeloggr::View::Account;
alias App::Changeloggr::View::Account under '/account';

require App::Changeloggr::View::Leaderboard;
alias App::Changeloggr::View::Leaderboard under '/leaderboard';

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

    p {
        outs "Fork us on ";
        hyperlink(
            label => "github",
            url   => "http://github.com/bestpractical/App-Changeloggr/tree/master",
        );
        outs "!";
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
        name => 'score',
        path => '/score',
    );

    render_region(
        name => 'vote_on_change',
        path => '/vote-on-change',
        defaults => {
            changelog => $changelog->id,
        },
    );

    show '/feedback/request_feedback';
};

template '/changelog/tags' => page {
    my $changelog = Changelog(name => get('changelog'));

    title is _('Tags for %1', $changelog->name);

    my $tags = $changelog->tags;
    dl {
        while (my $tag = $tags->next) {
            dt {
                outs $tag->text;
                outs _(" (hotkey: %1)", $tag->hotkey) if $tag->hotkey;
            }
            dd { $tag->description || $tag->tooltip || '' }
        }
    }

    hr {};

    p {
        hyperlink(
            label => _("Take me back to the voting booth."),
            url   => '/changelog/' . get('changelog'),
        );
    }
};

template '/changelog/download' => sub {
    my $changelog = Changelog( name => get('name') );
    Jifty->handler->apache->header_out( 'Content-Type' => 'text/plain' );
    outs_raw( $changelog->generate( get('format') ) );
};

template '/vote-on-change' => sub {
    my $change;
    my $changelog;

    if (get('change')) {
        $change = M('Change', id => get('change'));
        $changelog = $change->changelog;
        set(skipped_change => 1);
    }
    else {
        $changelog = M('Changelog', id => get('changelog'));
        $change = $changelog->choose_change;
        set(skipped_change => 0);
    }

    if ($change) {
        show_change($change);
    } else {
        my $has_changes = $changelog->changes->count;
        h2 { "No changes " . ($has_changes ? "left " : "") . " in this log" };
        p { "Thank you for all your votes!" } if $has_changes;
    }
};

template '/score' => sub {
    div {
        {id is "score"};
        my $user = Jifty->web->current_user->user_object;
        my ($votes, $place) = $user->vote_placement;

        outs _("You have %quant(%1,vote), and are ", $votes);
        hyperlink(
            label => _("currently ranked"),
            url   => '/leaderboard/global',
        );
        outs _(" #%1!", $place);
    };
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
            label => "[manage]",
        );
    }
}

sub show_change {
    my $change = shift;

    my $id = $change->id;

    show_vote_form($change);

    div {
        { class is "change" };

        p {
            { class is "identifier" };
            if (my $url = $change->external_source) {
                # the anchor is more for the iframe
                $url =~ s/#.*//;
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

        render_region(
            name => "change_message",
            path => "/change/message",
            arguments => {
                change => $change->id,
            },
        );

        ul {
            { class is "change_metadata" };
            li { "Author: " . $change->author };
            li { "Date: " . $change->date };
        };

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
    };
}

template '/change/message' => sub {
    my $change = M('Change', id => get('change'));
    p {
        attr { class is "change_message" };
        my $message = Jifty->web->escape($change->message);
        $message =~ s{\n}{<br />}g;
        my $links = $change->changelog->commit_links;
        $message = $_->linkify($message) while $_ = $links->next;
        outs_raw( $message );
    };

    my $rewording = Rewording(
        change_id => $change->id,
        user_id => Jifty->web->current_user->id,
    );
    if ($rewording->id) {
        p { "You submitted the following rewording:" };
        pre { $rewording->message };
    }
    else {
        hyperlink(
            label   => _("Reword this message?"),
            onclick => {
                replace_with => '/change/reword',
            },
        );
    }
};

template '/change/external_source' => sub {
    my $url = get('url');

    $url =~ s/#.*//
        if Jifty->web->current_user->user_object->strip_diff_anchor;

    iframe {
        class is 'external_source';
        src is $url;
    };
};

template '/change/more' => sub {
    my $change = M('Change', id => get('change'));

    pre {
        class is 'diffstat';

        my $diffstat = Jifty->web->escape($change->diffstat);

        for (['+', 'diffadd'], ['-', 'diffsub']) {
            my ($char, $class) = @$_;

            my $quoted_char = quotemeta $char;

            # this regex avoids coloring the symbols in filenames
            $diffstat =~ s{(\|\s+\d+ |</span>)($quoted_char+)}
                          {$1<span class="$class">$2</span>}g;
            $diffstat =~ s{((?:insertion|deletion)s?(?:&#40;|\())($quoted_char)(&#41;|\))}
                          {$1<span class="$class">$2</span>$3}g;
        }

        outs_raw $diffstat;
    };
};

sub show_vote_form {
    my $change = shift;
    my $changelog = $change->changelog;
    my $valid_tags = $change->prioritized_tags;
    my $next_change;

    if (get('skipped_change')) {
        $next_change = $changelog->choose_next_change(2);
    }
    else {
        $next_change = $changelog->choose_next_change;
    }

    div {
        id is 'vote_buttons';
        h4 { 'Vote!' };

        form {
            ul {
                my $vote = new_action(
                    class     => "CreateVote",
                    arguments => { change_id => $change->id }
                );

                render_param($vote, 'change_id');
                if ($valid_tags->count == 0 || $changelog->incremental_tags) {
                    render_param($vote, 'tag');

                    my $label = $changelog->incremental_tags ? 'Vote and add tag' : 'Vote';
                    li {
                        form_submit(
                            label   => $label,
                            onclick     => [
                                {
                                    submit       => $vote,
                                    refresh_self => 1,

                                    # only preload if we have a next change
                                    ($next_change && $next_change->id) ? (
                                        preload      => 'forward',
                                        arguments    => {
                                            change => $next_change->id,
                                        },
                                    ) : (
                                        arguments => {
                                            change => 0,
                                        },
                                    ),
                                },
                                { refresh => 'score' },
                            ],
                        );
                    }
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
                        }

                        li {
                            if ($valid_tag->hotkey) {
                                span {
                                    class is 'hotkey';
                                    $valid_tag->hotkey
                                };
                            }

                            $vote->button(
                                class       => "vote",
                                label       => $label,
                                key_binding => $valid_tag->hotkey,
                                tooltip     => $valid_tag->tooltip,
                                onclick     => [
                                    {
                                        submit => $vote,
                                        refresh_self => 1,

                                        # only preload if we have a next change
                                        ($next_change && $next_change->id) ? (
                                            preload      => 'forward',
                                            arguments    => {
                                                change => $next_change->id,
                                            },
                                        ) : (
                                            arguments => {
                                                change => 0,
                                            },
                                        ),
                                    },
                                    { refresh => 'score' },
                                ],
                                arguments   => { tag => $valid_tag->text },
                            );
                        };
                    }

                    p {
                        attr { class => 'tags_link' };
                        hyperlink(
                            label => _('Legend'),
                            url   => '/changelog/' . $changelog->name . '/tags',
                        );
                    }
                }
                hr {};
                li {
                    $vote->button(
                        class       => "vote",
                        label       => 'Skip this change',
                        onclick     => [
                            {
                                submit => $vote,
                                refresh_self => 1,

                                # only preload if we have a next change
                                ($next_change && $next_change->id) ? (
                                    preload      => 'forward',
                                    arguments    => {
                                        change => $next_change->id,
                                    },
                                ) : (
                                    arguments => {
                                        change => 0,
                                    },
                                ),
                            },
                            { refresh => 'score' },
                        ],
                        arguments   => { tag => '_skip' },
                    );
                };

                my $user = Jifty->web->current_user->user_object;
                if ($user->votes->count) {
                    my $undo = new_action('UndoVote');
                    li {
                        $undo->button(
                            class   => "vote",
                            label   => "Undo previous vote",
                            onclick     => [
                                { submit => $undo, refresh_self => 1 },
                                { refresh => 'score' },
                            ],
                        );
                    };
                }
            }
        }
    };
};

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

        render_hidden $create_rewording => 'change_id' => $change_id;
        render_param $create_rewording => (
            'message',
            label => '',
            default_value => $change->message,
            cols => 80,
        );

        $create_rewording->button(
            label => 'Reword',
            onclick => {
                submit => $create_rewording,
                replace_with => '/change/message',
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

