package App::Changeloggr::Action::Mixin::RequiresAdminToken;
use strict;
use warnings;
use JiftyX::ModelHelpers;

sub get_changelog {
    my $self = shift;

    return $self->record
        if $self->can('record')
        && $self->record->isa('App::Changeloggr::Model::Changelog');

    my $changelog = Changelog(
        admin_token => $self->argument_value('admin_token'),
        { current_user => App::Changeloggr::CurrentUser->superuser },
    );

    return $changelog;
}

sub validate_admin_token {
    my $self            = shift;
    my $got_admin_token = shift;

    my $changelog = $self->get_changelog;
    my $expected_admin_token = $changelog->as_superuser->admin_token;

    if ($expected_admin_token eq $got_admin_token) {
        return $self->validation_ok('admin_token');
    }
    else {
        return $self->validation_error(admin_token => "You do not have permission to add changes to this changelog.");
    }
}

1;

