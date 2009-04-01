use strict;
use warnings;

package App::Changeloggr::OutputFormat::Jifty;
use base qw/App::Changeloggr::OutputFormat/;

sub generate {
    my $class = shift;
    my %args = @_;

    my $str = "Changelog for ". $args{changelog}->name.", generated ".Jifty::DateTime->now."\n\n";
    for my $cat (sort keys %{$args{categories}}) {
        $str .= uc($cat) . "\n" . ("=" x length($cat)) . "\n";
        for my $change (@{$args{categories}{$cat}}) {
            my $msg = " * " . $change->message;
            $msg =~ s/\n*\Z//;
            $msg =~ s/\n/\n   /g;
            $msg =~ s/\n\s+\n/\n\n/g;
            $str .= $msg . "\n";
        }
        $str .= "\n";
    }
    return $str;
}

1;
