use strict;
use warnings;

package App::Changeloggr::Model::Change;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
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

