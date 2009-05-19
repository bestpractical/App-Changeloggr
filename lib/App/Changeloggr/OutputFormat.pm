use strict;
use warnings;

package App::Changeloggr::OutputFormat;

use Module::Pluggable (
    sub_name => 'output_formats',
);

1;
