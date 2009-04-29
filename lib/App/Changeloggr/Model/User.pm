use strict;
use warnings;

package App::Changeloggr::Model::User;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column name =>
        type is 'text',
        label is 'Name';

    column session_id =>
        type is 'text',
        render as 'hidden',
        is immutable;
};

sub since { '0.0.4' }

1;

