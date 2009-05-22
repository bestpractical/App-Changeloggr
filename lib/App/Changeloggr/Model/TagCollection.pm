package App::Changeloggr::Model::TagCollection;
use strict;
use warnings;
use base 'App::Changeloggr::Collection';

sub limit_to_visible {
    my $self = shift;

    if ($self->_handle->isa('Jifty::DBI::Handle::SQLite')) {
        $self->limit(
            column   => 'text',
            escape   => '\\',
            operator => 'NOT LIKE',
            value    => '\_%',
        );
    }
    elsif ($self->_handle->isa('Jifty::DBI::Handle::Pg')) {
        $self->limit(
            column      => 'text',
            operator    => 'NOT LIKE',
            value       => q{E'\\\\_%'},
            quote_value => 0,
        );
    }
    else {
        Carp::confess "You must use SQLite or Postgres, or fix Tags->limit_to_visible for your RDBMS. Sorry. :(";
    }

    return $self;
}

1;

