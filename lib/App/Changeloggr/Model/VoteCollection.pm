package App::Changeloggr::Model::VoteCollection;
use strict;
use warnings;
use base 'App::Changeloggr::Collection';

use constant results_are_readable => 1;

sub limit_to_commented {
    my $self = shift;
    $self->limit(
        column   => 'comment',
        operator => '!=',
        value    => '',
    );
    return $self;
}

sub group_by_voter {
    my $self = shift;

    $self->columns('user_id');
    $self->column(
        column   => 'id',
        function => 'COUNT(*)',
    );

    $self->group_by(
        column => 'user_id',
    );

    $self->order_by(
        function => 'COUNT(*)',
        order    => 'DESC',
    );

    return $self;
}

1;

