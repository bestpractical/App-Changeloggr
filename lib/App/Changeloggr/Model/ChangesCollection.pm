package App::Changeloggr::Model::ChangesCollection;
use strict;
use warnings;
use base 'App::Changeloggr::Collection';
use Params::Validate 'SCALAR';

sub create_from_text {
    my $self = shift;
    my %args = validate(@_, {
        text      => { type => SCALAR },
        changelog => { isa => 'App::Changeloggr::Model::Changelog' },
    });

    my $text      = $args{text};
    my $changelog = $args{changelog};

    while (length $text) {
        my $change = App::Changeloggr::Model::Change->new;
        my $newtext = $change->create_from_text(
            changelog => $changelog,
            text      => $text,
        );

        last if !defined($newtext);
        $text = $newtext;
    }

    return $text;
}

1;

