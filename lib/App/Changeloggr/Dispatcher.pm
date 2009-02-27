package App::Changeloggr::Dispatcher;
use Jifty::Dispatcher -base;

before '*' => run {
      my $top = Jifty->web->navigation;
      $top->child(Home => url => '/');
      $top->child(New => url => '/create-changelog', label => 'New Changelog');
};

on '/changelog/#' => run {
    set id => $1;
    show '/changelog';
};

1;

