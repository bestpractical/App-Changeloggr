package App::Changeloggr::Model::ChangeCollection;
use strict;
use warnings;
use base 'App::Changeloggr::Collection';
use Params::Validate qw(validate SCALAR BOOLEAN);

use constant results_are_readable => 1;

sub create_from {
    my $self = shift;
    my %args = validate(@_, {
        text      => { type => SCALAR, default => '' },
        parser    => { isa => 'App::Changeloggr::InputFormat' },
        changelog => { isa => 'App::Changeloggr::Model::Changelog' },
        events    => { type => SCALAR, default => 0 },
    });

    $args{parser} ||= App::Changeloggr::InputFormat->new( text => delete $args{text} );

    my $parser    = $args{parser};
    my $changelog = $args{changelog};

    my $last = 0;
    while (my $fields = $parser->next_match) {
        my $change = App::Changeloggr::Model::Change->new;

        my ($ok, $msg) = $change->create(
            %$fields,
            changelog_id => $changelog->id,
        );

        if ($ok) {
            $self->add_record($change);
            if ($args{events} and time > $last + $args{events}) {
                App::Changeloggr::Event::AddChanges->new(
                    { id => $changelog->id, change => $change }
                )->publish;
                $last = time;
            }
        } else {
            warn "Unable to create Change: $msg";
        }
    }
    App::Changeloggr::Event::AddChanges->new(
        { id => $changelog->id }
    )->publish if $args{events};
}

sub limit_to_voted {
    my $self = shift;

    my $votes = $self->join(
        type        => 'left',
        column1     => 'id',
        table2      => 'votes',
        column2     => 'change_id',
        is_distinct => 1,
    );

    $self->limit(
        column   => 'id',
        alias    => $votes,
        operator => 'IS NOT',
        value    => 'NULL',
    );

    return $self;
}

1;

