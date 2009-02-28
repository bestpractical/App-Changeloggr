package App::Changeloggr::Action::AddChanges;
use strict;
use warnings;

use JiftyX::ModelHelpers;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param admin_token =>
        type is 'text';

    param changes =>
        type is 'text',
        render as 'textarea',
        is mandatory,
        hints is 'We accept the output of svn log and git log.';
};

sub get_changelog {
    my $self = shift;

    my $changelog = Changelog(
        admin_token => $self->argument_value('admin_token'),
        { current_user => App::Changeloggr::CurrentUser->superuser },
    );

    return $changelog;
}

sub validate_admin_token {
    my $self        = shift;
    my $admin_token = shift;

    my $changelog = $self->get_changelog;

    if ($changelog->admin_token eq $admin_token) {
        return $self->validation_ok('admin_token');
    }
    else {
        return $self->validation_error(admin_token => "You do not have permission to add changes to this changelog.");
    }
}

sub take_action {
    my $self = shift;
    my $changelog = $self->get_changelog;
}

1;

