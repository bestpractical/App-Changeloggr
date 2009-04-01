package App::Changeloggr::Action::CreateTag;
use strict;
use warnings;
use base 'App::Changeloggr::Action::Mixin::RequiresAdminToken', 'Jifty::Action::Record::Create';

sub canonicalize_text {
    my $self = shift;
    my $tag = shift;

    if (length $tag and not length($self->argument_value('hotkey')||'')) {
        my $possible = lc substr($tag, 0, 1);
        my $existing = App::Changeloggr::Model::TagCollection->new;
        $existing->limit( column => 'changelog_id', value => $self->argument_value('changelog_id') );
        $existing->limit( column => 'hotkey',       value => $possible );
        $self->argument_value( hotkey => $possible ) unless $existing->count;
    }
    return $tag;
}

sub take_action {
    my $self = shift;
    $self->record->current_user(App::Changeloggr::CurrentUser->superuser);
    $self->SUPER::take_action(@_);
}

sub report_success {
    my $self = shift;
    $self->result->message(_('Added the "%1" tag', $self->record->text));
}

1;


