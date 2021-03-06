package App::Changeloggr::Action::AddChanges;
use strict;
use warnings;
use base 'App::Changeloggr::Action::Mixin::RequiresAdminToken', 'Jifty::Action';

use Jifty::Param::Schema;
use Jifty::Action schema {
    param admin_token =>
        type is 'text';

    param changes =>
        type is 'text',
        render as 'upload',
        label is 'Select change file',
        is mandatory;
};

sub take_action {
    my $self = shift;

    my $parser = App::Changeloggr::InputFormat->new( file => $self->argument_value('changes') );
    $self->argument_value( changes => undef );
    unless ($parser) {
        return $self->validation_error( changes => "That doesn't look like a log format we recognize." );
    }

    my $changelog = $self->get_changelog;

    if (Jifty->config->app('BackgroundImport') && $parser->take_offline) {
        Jifty->background( sub { $changelog->add_changes( parser => $parser, events => 2 ) } );
        $self->result->message(_("Importing your changes in the background."));
    } else {
        my $changes = $changelog->add_changes( parser => $parser );

        if ($changes->count) {
            $self->result->message(_("Added your %quant(%1,change)!", $changes->count));
        }
        else {
            $self->result->message("No changes to add.");
        }
    }
}

1;

