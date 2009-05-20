use strict;
use warnings;

package App::Changeloggr::Model::News;
use Jifty::DBI::Schema;

use App::Changeloggr::Model::User;

use App::Changeloggr::Record schema {
    column author =>
        refers_to App::Changeloggr::Model::User,
        default is defer { Jifty->web->current_user->id },
        is protected,
        since '0.0.12';
};

use Jifty::Plugin::SiteNews::Mixin::Model::News;

use constant since => '0.0.12';

sub current_user_can {
    my $self = shift;
    my $right = shift;
    return 1 if $right eq "read";
    return 1 if $self->current_user->user_object and $self->current_user->user_object->access_level eq "staff";
    return 0;
}

1;

