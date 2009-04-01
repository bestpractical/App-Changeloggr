package App::Changeloggr::Action::UpdateChangelog;
use strict;
use warnings;
use base 'App::Changeloggr::Action::Mixin::RequiresAdminToken', 'Jifty::Action::Record::Update';

sub take_action {
    my $self = shift;
    $self->record->current_user(App::Changeloggr::CurrentUser->superuser);
    $self->SUPER::take_action(@_);
}

1;

