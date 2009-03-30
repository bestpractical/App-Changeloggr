package App::Changeloggr;
use strict;
use warnings;

use App::Changeloggr::LogFormat;

sub start {
    my $class = shift;

    # Find all log format parsers
    Jifty::Module::Pluggable->import(
        search_path => 'App::Changeloggr::LogFormat',
        require     => 1,
        inner       => 0,
        sub_name    => 'log_formats',
    );
}

1;

