package App::Changeloggr::Dispatcher;
use Jifty::Dispatcher -base;
use JiftyX::ModelHelpers;

before '*' => run {
      my $top = Jifty->web->navigation;
      $top->child(Home => url => '/');
      $top->child(New => url => '/admin/create-changelog', label => 'New Changelog');
      Jifty->web->session->expires( '+1y' );
};

on '/admin/created-changelog' => run {
    my $id = Jifty->web->response->result('create-changelog')->content('id');
    my $admin_token = Changelog($id)->as_superuser->admin_token;
    redirect "/admin/changelog/$admin_token";
};

on '/changelog/*' => run {
    set name => $1;
    show '/changelog';
};

on '/changelog/*/Changes' => run {
    set name => $1;
    show '/changelog/download';
};

on '/changelog/*/*/Changes' => run {
    set name => $1;
    set format => $2;
    show '/changelog/download';
};

on '/admin/changelog/*' => run {
    my $uuid = $1;
    set id => Changelog(admin_token => $uuid)->id;
    show '/admin/changelog';
};

1;

