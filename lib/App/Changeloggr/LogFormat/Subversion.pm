package App::Changeloggr::LogFormat::Subversion;
use base qw/App::Changeloggr::LogFormat/;
use strict;
use warnings;

use DateTime::Format::Strptime;
use constant DATE_PARSER => DateTime::Format::Strptime->new(
    pattern => '%F %T %z',
);

sub matches {
    my $self = shift;
    my %args = @_;

    return $args{text} =~ /\A-{72}\r?\nr\d+ \| \S+ \| \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \S+ \(.*?\) \| \d+ lines?/;
}

sub next_match {
    my $self = shift;

    $self->{text} =~ s{
        \A
        (
            ^ -{72} \r? \n
            (r.*?) \s+ \|
            \s+ (.*?) \s+ \|
            \s+ (\d{4}-\d{2}-\d{2} \s+ \d{2}:\d{2}:\d{2}\s+\S+) \s+ \(.*?\) \s+ \|
            \s+ \d+ \s+ lines? \r? \n \r? \n
            ( .*? )
        )
        (?=
            ^ -{72} \r? \n
        )
    }{}xms or return;

    my %fields;
    $fields{raw} = $1;
    $fields{identifier} = $2;
    $fields{author} = $3;
    $fields{date} = DATE_PARSER->parse_datetime($4);
    $fields{message} = $5;

    return \%fields;
}

=begin svn-sample

------------------------------------------------------------------------
r18997 | ruz | 2009-03-31 10:32:02 -0400 (Tue, 31 Mar 2009) | 1 line

* after load check if we actually loaded the user
------------------------------------------------------------------------
r18996 | ruz | 2009-03-31 06:51:57 -0400 (Tue, 31 Mar 2009) | 1 line

* more principal_id -> principal
------------------------------------------------------------------------
r18995 | acme | 2009-03-31 05:41:05 -0400 (Tue, 31 Mar 2009) | 2 lines

Remove sunnavy's use lib

------------------------------------------------------------------------
=cut

1;
