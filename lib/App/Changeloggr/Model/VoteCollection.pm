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

1;

