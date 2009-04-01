package App::Changeloggr::InputFormat::SubversionXML;
use base qw/App::Changeloggr::InputFormat/;
use strict;
use warnings;

use XML::Simple;
use DateTime::Format::Strptime;
use constant DATE_PARSER => DateTime::Format::Strptime->new(
    pattern => '%FT%T',
);

sub matches {
    my $self = shift;
    my %args = @_;

    return $args{text} =~ /\A<\?xml\s+version="1.0"\?>\s+<log>\s+<logentry\s+revision="?\d+"?>/;
}

sub next_match {
    my $self = shift;

    unless ( $self->{log_entries} ) {
        my $data = XMLin( $self->{text}, ForceArray => ["logentry"] );
        $self->{log_entries} = [map {
            {
                identifier => "r" . $_->{revision},
                author     => $_->{author},
                date       => DATE_PARSER->parse_datetime( $_->{date} ),
                message    => $_->{msg},
                raw        => XMLout($_, NoAttr => 1), # Rather a hack
            };
        } @{ $data->{logentry} }];
    }

    return shift @{ $self->{log_entries} };
}

=begin svn-sample
<?xml version="1.0"?>
<log>
<logentry
   revision="5662">
<author>glasser</author>
<date>2006-07-27T18:26:08.845218Z</date>
<msg>XML::WBXML actually works on Perl 5.6.0; requirement change requested by aaron@freebsd.org.</msg>
</logentry>
<logentry
   revision="3645">
<author>glasser</author>
<date>2005-08-12T03:04:20.416142Z</date>
<msg>Thingy</msg>
</logentry>
<logentry
   revision="3644">
<author>glasser</author>
<date>2005-08-12T02:44:08.798828Z</date>
<msg>Moose</msg>
</logentry>
<logentry
   revision="3643">
<author>glasser</author>
<date>2005-08-12T01:35:10.934580Z</date>
<msg>Woo</msg>
</logentry>
<logentry
   revision="3642">
<author>glasser</author>
<date>2005-08-12T00:18:18.113445Z</date>
<msg>start XML::WBXML project</msg>
</logentry>
</log>

=cut

1;
