package App::Changeloggr::Action::CreateVote;
use strict;
use warnings;
use base 'Jifty::Action::Record::Create';
use JiftyX::ModelHelpers;

sub validate_tag {
    my $self = shift;
    my $tag  = shift;

    # if the admin has set up a set of tags for this project, then validate
    # against that list
    my $valid_tags = Changelog($self->argument_value('changelog'))->tags;
    if ($valid_tags->count) {
        while (my $valid_tag = $valid_tags->next) {
            return $self->validation_ok('tag') if $valid_tag eq $tag;
        }

        return $self->validation_error(tag => "That is not a valid tag for this changelog.");
    }

    # otherwise, every tag is valid
    return $self->validation_ok('tag');
}

sub report_success { shift->result->message(_("Thanks for voting!")) }

1;

