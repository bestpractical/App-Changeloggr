package App::Changeloggr::LogFormat::Git;
use base qw/App::Changeloggr::LogFormat/;
use strict;
use warnings;

use DateTime::Format::Strptime;
use constant DATE_PARSER => DateTime::Format::Strptime->new(
    pattern => '%a %b %d %T %Y %z',
);

sub matches {
    my $self = shift;
    my %args = @_;

    return $args{text} =~ /^commit \w+\r?\n/;
}
    
sub next_match {
    my $self = shift;

    # git log --pretty=fuller --stat
    $self->{text} =~ s{
        \A
        (
            ^ commit \  \w+ \n
            .*?
        )
        (?=
            \Z
            |
            ^ commit \  \w+ \n
        )
    }{}xms;

    my $entry = $1
        or return;
    my %fields;

    $fields{raw} = $entry;

    if ($entry =~ /^commit (.*)$/im) {
        $fields{identifier} = $1;
    }
    if ($entry =~ /^Author:\s*(.*)$/im) {
        $fields{author} = $1;
    }
    if ($entry =~ /^(?:Author)?Date:\s*(.*)$/im) {
        $fields{date} = DATE_PARSER->parse_datetime($1);
    }
    # We don't have these columns in the database yet
#    if ($entry =~ /^Commit:\s*(.*)$/im) {
#        $fields{commit} = $1;
#    }
#    if ($entry =~ /^CommitDate:\s*(.*)$/im) {
#        $fields{commit_date} = $1;
#    }

    if ($entry =~ /.*?^(\s{4}.*?)(^\s{1,2}\S+\s+\|\s+\d+|\z)/ims) {
        $fields{message} = $1;
    }
    if ($entry =~ /\n(\s{1,2}\S+\s+\|\s+\d+.*)$/ims) {
        $fields{diff} = $1;
    }

    return \%fields;
}

=begin git-sample

(this is produced by git log --pretty=fuller --stat)

commit 8837a66df7e8959d3101a5227d7b3c597990c0d0
Author:     Nicholas Clark <nick@ccl4.org>
AuthorDate: Tue Dec 2 20:16:33 2008 +0000
Commit:     David Mitchell <davem@iabyn.com>
CommitDate: Wed Jan 28 00:05:55 2009 +0000

    Codify the current behaviour of evals which define subroutines before
    failing (due to syntax errors).
    
    p4raw-id: //depot/perl@34984
    
    (cherry picked from commit 99d3381e871dbd1d94b47516b4475d85b3935ac6)

 t/comp/retainedlines.t |   23 ++++++++++++++++++++++-
 1 files changed, 22 insertions(+), 1 deletions(-)

=cut

1;
