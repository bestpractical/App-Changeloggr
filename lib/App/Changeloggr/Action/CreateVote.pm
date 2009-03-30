package App::Changeloggr::Action::CreateVote;
use strict;
use warnings;
use base 'Jifty::Action::Record::Create';

sub record_class { 'App::Changeloggr::Model::Vote' }

sub report_success { shift->result->message(_("Thanks for voting!")) }

1;

