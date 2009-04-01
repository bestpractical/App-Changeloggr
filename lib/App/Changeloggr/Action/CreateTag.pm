package App::Changeloggr::Action::CreateTag;
use strict;
use warnings;
use base 'App::Changeloggr::Action::Mixin::RequiresAdminToken', 'Jifty::Action::Record::Create';

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


