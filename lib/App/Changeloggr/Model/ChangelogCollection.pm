package App::Changeloggr::Model::ChangelogCollection;
use strict;
use warnings;
use base 'App::Changeloggr::Collection';

sub with_changes {
    my $self = shift;
    Carp::croak("with_changes takes no arguments") if @_;

    my $changes = $self->join(
        type    => 'left',
        alias1  => 'main',
        column1 => 'id',
        table2  => 'changes',
        column2 => 'changelog',
    );

    #$self->limit(
    #    leftjoin => $changes,
    #    # hmm..
    #);

    return $self;
}

1;

