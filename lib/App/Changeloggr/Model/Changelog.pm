use strict;
use warnings;

package App::Changeloggr::Model::Changelog;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
  column name =>
        type is 'text',
        label is 'Project name';
};

1;

