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
        my ($fields, $newtext) = $self->extract_change_data_from_text($text);
        last if !defined($newtext);

        my $change = App::Changeloggr::Model::Change->new;
        $change->create(
            %$fields,
            changelog => $changelog,
        );
        $self->add_record($change);

        $text = $newtext;
    }

    return $text;
}

sub extract_change_data_from_text {
    my $self = shift;
    my $text = shift;
    my %fields;



    return (\%fields, $text);
}

1;

