package App::Changeloggr::Model::ChangeCollection;
use strict;
use warnings;
use base 'App::Changeloggr::Collection';
use Params::Validate qw(validate SCALAR);

use constant results_are_readable => 1;

sub create_from_text {
    my $self = shift;
    my %args = validate(@_, {
        text      => { type => SCALAR },
        changelog => { isa => 'App::Changeloggr::Model::Changelog' },
    });

    my $parser = App::Changeloggr::LogFormat->new( text => delete $args{text} );
    return $self->create_from_parser( %args, parser => $parser );
}

sub create_from_parser {
    my $self = shift;
    my %args = validate(@_, {
        parser    => { isa => 'App::Changeloggr::LogFormat' },
        changelog => { isa => 'App::Changeloggr::Model::Changelog' },
    });

    my $parser    = $args{parser};
    my $changelog = $args{changelog};

    while (my $fields = $parser->next_match) {
        my $change = App::Changeloggr::Model::Change->new;

        my ($ok, $msg) = $change->create(
            %$fields,
            changelog => $changelog,
        );

        if ($ok) {
            $self->add_record($change);
        } else {
            warn "Unable to create Change: $msg";
        }
    }
}

1;

