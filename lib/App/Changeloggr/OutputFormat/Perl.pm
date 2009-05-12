use strict;
use warnings;

package App::Changeloggr::OutputFormat::Perl;
use base qw/App::Changeloggr::OutputFormat/;

sub generate {
    my $class = shift;
    my %args = @_;

    my $name  = $args{changelog}->name;
    my $version = $name =~ /(\d+\.(\d+)\.\d+)/ ? $1 : $name;
    my $release = ($2 and $2 % 2) ? "development release" : "release";

    my $str = <<EOT;
=head1 NAME

perldelta - what is new for $version

=head1 DESCRIPTION

This document describes differences between the __PREVIOUS__  and the $version
$release.
EOT

    for my $cat (sort keys %{$args{categories}}) {
        $str .= "\n=head1 $cat\n\n";

        my @changes = map  { $_->[0] }
                      sort { $a->[1] <=> $b->[1] }
                      map  { [$_, $_->numeric_importance] }
                      @{$args{categories}{$cat}}

        for my $change (@changes) {
            my($summary) = $change->message =~ /\A(.*)$/m;
            $str .= "=head2 $summary\n\n" . $change->message . "\n";
        }
    }
    $str .= "=cut\n\n";
    return $str;
}

1;
