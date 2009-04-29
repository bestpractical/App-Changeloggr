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

# match /admin/changelog/SUBTAB/UUID
# or    /admin/changelog/UUID
on qr{^/admin/changelog/([^/]+)(?:/([^/]+))?$} => run {
    my ($subpage, $uuid) = ($1, $2);
    if (!$uuid) {
        $uuid = $subpage;
        undef $subpage;
    }

    my $cl = Changelog(admin_token => $uuid);
    show "/errors/404" unless $cl->id;

    my $admin = Jifty->web->navigation->child(
        $cl->name => url => "/admin/changelog/$uuid",
        active => 1,
    );
    $admin->child(
        Changes => url => "/admin/changelog/changes/$uuid",
        label   => "Upload changes",
    );
    $admin->child(
        Tags => url => "/admin/changelog/tags/$uuid",
    );
    $admin->child(
        Links => url => "/admin/changelog/links/$uuid",
    );
    $admin->child(
        Votes => url => "/admin/changelog/votes/$uuid",
    );

    set id => $cl->id;
    show "/admin/changelog" . ($subpage ? "/$subpage" : "");
};

1;

