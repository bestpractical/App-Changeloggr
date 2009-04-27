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
        redirect '/create-changelog';
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
        show_change($change);
        show_vote_form($change);
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
            url => "/changelog/$admin_token/admin",
            label => "[administrate]",
        );
    }
}

sub show_change {
    my $change = shift;

    h3 {
        { class is "change" };
        outs( $change->message );
    }
}

sub show_vote_form {
    my $change = shift;

    my $valid_tags = $change->changelog->tags;

    form {
        my $vote = new_action(
            class     => "CreateVote",
            arguments => { change_id => $change->id }
        );

        if ($valid_tags->count == 0) {
            render_action $vote;
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
    }
}

1;

