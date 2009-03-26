package App::Changeloggr;
use strict;
use warnings;

sub identify_format {
    my $self = shift;
    my $text = shift;

    if ($text =~ /^commit \w+\n/) {
        return 'git';
    }

    return;
}

1;

