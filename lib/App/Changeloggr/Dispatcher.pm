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

on '/changelog/admin/*' => run {
    my $uuid = $1;

    my $changelog = App::Changeloggr::Model::Changelog->new;
    $changelog->load_by_cols(admin_token => $uuid);

    set id => $changelog->id;
    show '/changelog/admin';
};

1;

