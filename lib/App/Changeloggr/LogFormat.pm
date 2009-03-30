package App::Changeloggr::LogFormat;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;
    return unless $args{text};

    $args{text} =~ s/^\s+//;
    $args{text} =~ s/\r\n/\n/g;

    if ($class eq "App::Changeloggr::LogFormat") {
        for my $format (App::Changeloggr->log_formats) {
            return $format->new( @_ ) if $format->matches( @_ );
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
