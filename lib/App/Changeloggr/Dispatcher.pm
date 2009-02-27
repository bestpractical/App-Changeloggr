package App::Changeloggr::Dispatcher;
use Jifty::Dispatcher -base;
use JiftyX::ModelHelpers;

before '*' => run {
      my $top = Jifty->web->navigation;
      $top->child(Home => url => '/');
      $top->child(New => url => '/create-changelog', label => 'New Changelog');
};

on '/created-changelog' => run {
    my $id = Jifty->web->response->result('create-changelog')->content('id');
    redirect '/changelog/admin/' . Changelog($id)->as_superuser->admin_token;
};

on '/changelog/*' => run {
    set name => $1;
    show '/changelog';
};

on '/changelog/admin/*' => run {
    my $uuid = $1;
    set id => Changelog(admin_token => $uuid)->id;
    show '/changelog/admin';
};

1;

