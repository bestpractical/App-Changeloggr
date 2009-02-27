use strict;
use warnings;

package App::Changeloggr::Model::Vote;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
    column change =>
        refers_to App::Changeloggr::Model::Change;

    column user_session_id =>
        type is 'text';
};

1;

