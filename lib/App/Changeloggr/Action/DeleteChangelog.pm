package App::Changeloggr::Action::DeleteChangelog;
use strict;
use warnings;
use base 'App::Changeloggr::Action::Mixin::RequiresAdminToken', 'Jifty::Action::Record::Delete';

sub take_action {
    my $self = shift;
    $self->record->current_user(App::Changeloggr::CurrentUser->superuser);
    $self->SUPER::take_action(@_);
}

1;

