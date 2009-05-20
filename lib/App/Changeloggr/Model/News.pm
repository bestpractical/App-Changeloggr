use strict;
use warnings;

package App::Changeloggr::Model::News;
use Jifty::DBI::Schema;

use App::Changeloggr::Record schema {
};

use Jifty::Plugin::SiteNews::Mixin::Model::News;

use constant since => '0.0.12';

sub current_user_can {
    return 1;
}

1;

