package App::Changeloggr::Collection;
use strict;
use warnings;
use base 'Jifty::Collection';

sub limit_to_visible {
    my $self   = shift;
    my $column = shift
        or die "limit_to_visible takes a column name";

    if ($self->_handle->isa('Jifty::DBI::Handle::SQLite')) {
        $self->limit(
            column   => $column,
            escape   => '\\',
            operator => 'NOT LIKE',
            value    => '\_%',
        );
    }
    elsif ($self->_handle->isa('Jifty::DBI::Handle::Pg')) {
        $self->limit(
            column      => $column,
            operator    => 'NOT LIKE',
            value       => q{E'\\\\_%'},
            quote_value => 0,
        );
    }
    else {
        Carp::confess "You must use SQLite or Postgres, or fix App::Changeloggr::Collection->limit_to_visible for your RDBMS. Sorry. :(";
    }

    return $self;
}

1;


