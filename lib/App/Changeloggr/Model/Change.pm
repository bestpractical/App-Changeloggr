use strict;
use warnings;

package App::Changeloggr::Model::Change;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
  column changelog =>
        refers_to App::Changeloggr::Model::Changelog;

  column author =>
        type is 'text',
        label is 'Author';

  column body =>
        type is 'text',
        label is 'Body';

  column diff =>
        type is 'text',
        label is 'Diff';
};

1;

