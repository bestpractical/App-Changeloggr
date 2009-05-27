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

sub take_offline {
    my $self = shift;

    return length($self->{text}) > 4 * 1024; # 4k of text or more
}

sub strip_detritus {
    my $self = shift;
    my $msg  = shift;

    # git-svn metadata
    $msg =~ s/^git-svn-id: .*$//m;

    # strip potentially-nested svk headers
    # this intentionally does not match any line in the message, since
    # that could lose merge information
    while ($msg =~ s/^\s*r\d+\@\S+:\s*\S+\s*\|\s*.*\n//) {
        $msg =~ s/^ //g;
    }

    # Remove extra newlines at the end of the message
    $msg =~ s/\s+\z//;

    $msg = $self->strip_leading_whitespace($msg);

    return $msg;
}

sub strip_leading_whitespace {
    my $self = shift;
    my $msg  = shift;

    # Find the minimum amount of whitespace on a non-empty line
    my $minimum;
    for my $line (grep { /\S/ } split /\n/, $msg) {
        my ($space) = $line =~ /^( *)/;
        $minimum = length($space)
            if !defined($minimum)
            || $minimum > length($space);
    }

    # Remove that minimum from each line
    $msg =~ s/^( {$minimum})//mg;

    return $msg;
}

1;
