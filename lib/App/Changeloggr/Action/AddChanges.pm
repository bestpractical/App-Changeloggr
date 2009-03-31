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
        render as 'upload',
        is mandatory,
        hints is 'Formats we accept: git log --pretty=fuller --stat, svn log, or svn log --xml';
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

    my $parser = App::Changeloggr::LogFormat->new( file => $self->argument_value('changes') );
    $self->argument_value( changes => undef );
    unless ($parser) {
        return $self->validation_error( changes => "That doesn't look like a log format we recognize." );
    }

    my $changelog = $self->get_changelog;
    my $changes = $changelog->add_changes( $parser );

    if ($changes->count) {
        $self->result->message(_("Added your %quant(%1,change)!", $changes->count));
    }
    else {
        $self->result->message("No changes to add.");
    }
}

1;

