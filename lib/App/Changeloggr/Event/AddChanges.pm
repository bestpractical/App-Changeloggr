package App::Changeloggr::Event::AddChanges;
use strict;
use warnings;
use base 'App::Changeloggr::Event';

sub match {
    my $self    = shift;
    my $query   = shift;

    return if $query->{id} and $self->data->{id} != $query->{id};
    return 1;
}

sub render_arguments {
    my $self = shift;
    return ( %{$self->data} );
}

1;
