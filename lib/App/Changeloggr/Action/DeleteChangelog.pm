package App::Changeloggr::Action::DeleteChangelog;
use strict;
use warnings;
use base 'Jifty::Action::Record::Delete';

sub record_class { 'App::Changeloggr::Model::Changelog' }

sub validate_admin_token {
    my $self        = shift;
    my $admin_token = shift;

    if ($self->record->as_superuser->admin_token eq ($admin_token||'')) {
        return $self->validation_ok('admin_token');
    }
    else {
        return $self->validation_error(admin_token => "You do not have permission to delete this changelog.");
    }
}

sub take_action {
    my $self = shift;
    $self->record->current_user(App::Changeloggr::CurrentUser->superuser);
    $self->SUPER::take_action(@_);
}

1;

