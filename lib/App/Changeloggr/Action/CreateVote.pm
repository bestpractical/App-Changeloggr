package App::Changeloggr::Action::CreateVote;
use strict;
use warnings;
use base 'Jifty::Action::Record::Create';
use JiftyX::ModelHelpers;

sub validate_tag {
    my $self = shift;
    my $tag  = shift;

    my $changelog = Changelog($self->argument_value('changelog_id'));
    if (!$changelog->id) {
        my $change = Change($self->argument_value('change_id'));
        $changelog = $change->changelog;
    }

    return $self->validation_error(change_id => "No change provided")
        if !$changelog->id;

    # private tags are always okay
    return $self->validation_ok('tag') if $tag =~ /^_/;

    # if the admin wants incremental tag creation for this project, then
    # add this tag before voting
    if (!$changelog->has_tag($tag) && $changelog->incremental_tags) {
        my ($ok, $msg) = $changelog->add_tag($tag);
        return $self->validation_ok('tag') if $ok;
        return $self->validation_error(tag => $msg);
    }

    # if the admin has set up a set of tags for this project, then validate
    # against that list
    my $valid_tags = $changelog->tags;
    if ($valid_tags->count) {
        while (my $valid_tag = $valid_tags->next) {
            return $self->validation_ok('tag') if $valid_tag->text eq $tag;
        }

        return $self->validation_error(tag => "That is not a valid tag for this changelog.");
    }

    # otherwise, every tag is valid
    return $self->validation_ok('tag');
}

sub report_success {
    my $self = shift;

    # Don't thank the user for skipping the change
    $self->result->message(_("Thanks for voting!"))
        unless $self->argument_value('tag') =~ /^_/;
}

1;

