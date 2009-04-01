package App::Changeloggr::InputFormat;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;
    return unless $args{text} or $args{file};

    if (my $fh = delete $args{file}) {
        $args{text} = do { local $/; <$fh>};
    }

    $args{text} =~ s/^\s+//;
    $args{text} =~ s/\r\n/\n/g;

    return unless $args{text} =~ /\S/;

    if ($class eq __PACKAGE__) {
        for my $format (App::Changeloggr->log_formats) {
            return $format->new( %args ) if $format->matches( %args );
        }
        return undef;
    }

    return bless \%args, $class;
}

sub matches {
    my $class = shift;
    return 0;
}

sub next_match {
    return undef;
}

1;
