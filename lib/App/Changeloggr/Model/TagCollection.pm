package App::Changeloggr::Model::TagCollection;
use strict;
use warnings;
use base 'App::Changeloggr::Collection';

sub limit_to_visible {
    my $self   = shift;
    my $column = shift || 'text';

    $self->SUPER::limit_to_visible($column, @_);
}

1;

