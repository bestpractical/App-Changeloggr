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
    if (Jifty->config->app('Production')) {
        outs_raw(<<'EOT');
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("UA-937849-6");
pageTracker._trackPageview();
} catch(err) {}</script>});
EOT
    }

    $self->SUPER::render_footer(@_);
}

1;
