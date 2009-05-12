package App::Changeloggr::View::Page;
use strict;
use warnings;
use base qw/Jifty::View::Declare::Page/;

use Jifty::View::Declare::Helpers;

sub render_footer {
    my $self = shift;
    div {
        attr { id is "footer" };
    };
    $self->SUPER::render_footer(@_);
}

1;
