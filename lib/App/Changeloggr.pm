package App::Changeloggr;
use strict;
use warnings;

use App::Changeloggr::InputFormat;
use App::Changeloggr::OutputFormat;

sub start {
    my $class = shift;

    # Find all log format parsers
    Jifty::Module::Pluggable->import(
        search_path => 'App::Changeloggr::InputFormat',
        require     => 1,
        inner       => 0,
        sub_name    => 'log_formats',
    );

    # Find all log format generators
    Jifty::Module::Pluggable->import(
        search_path => 'App::Changeloggr::OutputFormat',
        require     => 1,
        inner       => 0,
        sub_name    => 'output_formats',
    );
}

1;

