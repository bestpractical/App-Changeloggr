use strict;
use warnings;

package App::Changeloggr::OutputFormat;

use Module::Pluggable (
    sub_name => 'output_formats',
);

sub generate {
    my $class = shift;
    my($categories) = @_;
    # ...
    return "";
}

1;
