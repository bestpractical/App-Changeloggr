package App::Changeloggr::Action::CreateVote;
use strict;
use warnings;
use base 'Jifty::Action::Record::Create';

sub report_success { shift->result->message(_("Thanks for voting!")) }

1;

