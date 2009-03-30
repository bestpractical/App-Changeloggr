package App::Changeloggr::Model::ChangeCollection;
use strict;
use warnings;
use base 'App::Changeloggr::Collection';
use Params::Validate qw(validate SCALAR);
use DateTime::Format::Strptime;

my $gitdate = DateTime::Format::Strptime->new(
    pattern => '%a %b %d %T %Y %z',
);

sub create_from_text {
    my $self = shift;
    my %args = validate(@_, {
        text      => { type => SCALAR },
        changelog => { isa => 'App::Changeloggr::Model::Changelog' },
    });

    my $text      = $args{text};
    my $changelog = $args{changelog};

    while ($text =~ /\S/) {
        my ($fields, $newtext) = $self->extract_change_data_from_text($text);
        last if !defined($newtext);

        my $change = App::Changeloggr::Model::Change->new;
        $change->create(
            %$fields,
            changelog => $changelog,
        );
        $self->add_record($change);

        $text = $newtext;
    }

    return $text;
}

sub identify_format {
    my $self = shift;
    my $text = shift;

    if ($text =~ /^commit \w+\r?\n/) {
        return 'git';
    }

    return;
}

sub extract_change_data_from_text {
    my $self = shift;
    my $text = shift;

    $text =~ s/^\s+//;
    $text =~ s/\r\n/\n/g;

    my $format = $self->identify_format($text);
    die "I'm unable to handle the change text format: " . substr($text, 0, 30) . '...'
        if !defined($format);

    my $extract_method = "extract_change_data_from_$format";
    return $self->$extract_method($text);
}

sub extract_change_data_from_git {
    my $self = shift;
    my $text = shift;

    # git log --format=fuller --stat
    $text =~ s{
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

    if ($entry =~ /^commit (.*)$/im) {
        $fields{identifier} = $1;
    }
    if ($entry =~ /^Author:\s*(.*)$/im) {
        $fields{author} = $1;
    }
    if ($entry =~ /^(?:Author)?Date:\s*(.*)$/im) {
        $fields{date} = $gitdate->parse_datetime($1);
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

    return (\%fields, $text);
}

=begin git-sample

(this is produced by git log --format=fuller --stat)

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

