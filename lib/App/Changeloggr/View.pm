package App::Changeloggr::View;
use Jifty::View::Declare -base;
use JiftyX::ModelHelpers;
use strict;
use warnings;

require App::Changeloggr::View::Admin;
alias App::Changeloggr::View::Admin under '/admin';

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
        redirect '/admin/create-changelog';
    }
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
    }
};

sub changelog_summary {
    my $changelog = shift;

    hyperlink(
        url   => '/changelog/' . $changelog->name,
        label => $changelog->name,
    );

    if (Jifty->config->framework('DevelMode')) {
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

    div {
        { class is "change" };

        h3 {
            { class is "change_message" };
            my $message = Jifty->web->escape($change->message);
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
        if (my $url = $change->external_source) {
            hyperlink(
                label  => "Full diff",
                url    => $url,
                target => "diff",
                class  => "external_source",
            );
        }
        hyperlink(
            label => 'more...',
            onclick => [{
                region       => Jifty->web->qualified_region("change_$id"),
                replace_with => '/change/more',
                toggle       => 1,
                effect       => 'slideDown',
                arguments    => {
                    change => $id,
                },
            },
            "this.innerHTML = this.innerHTML == 'more...' ? 'less...' : 'more...';",
        ]);
        div {
            render_region("change_$id");
        };

        if ($args{voting_form}) {
            hr {};
            show_vote_form($change);
        }

        show_vote_comments($change);
    };
}

template '/change/more' => sub {
    my $change = M('Change', id => get('change'));

    pre {
        my $diffstat = Jifty->web->escape($change->diffstat);
        $diffstat =~ s{(\++)}{<span class="diffadd">$1</span>}g;
        $diffstat =~ s{(\-+)}{<span class="diffsub">$1</span>}g;

        outs_raw $diffstat;
    };
};

sub show_vote_form {
    my $change = shift;

    my $valid_tags = $change->changelog->tags;

    form {
        h4 { 'Vote!' };
        my $vote = new_action(
            class     => "CreateVote",
            arguments => { change_id => $change->id }
        );

        if ($valid_tags->count == 0) {
            render_action $vote, ['change_id', 'tag'];
            form_submit(
                label   => 'Vote',
                onclick => { submit => $vote, refresh_self => 1 }
            );
        }
        else {
            render_action $vote, ['change_id'];
            while (my $valid_tag = $valid_tags->next) {
                $vote->button(
                    class => "vote",
                    label => $valid_tag->text,
                    key_binding => $valid_tag->hotkey,
                    onclick => { submit => $vote, refresh_self => 1 },
                    arguments => { tag => $valid_tag->text },
                );
            }
        }

        render_param($vote, 'comment');
    }
}

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

