package App::Changeloggr::Dispatcher;
use Jifty::Dispatcher -base;
use JiftyX::ModelHelpers;

before '*' => run {
      my $top = Jifty->web->navigation;
      $top->child(Home => url => '/');
      $top->child(New => url => '/admin/create-changelog', label => 'New Changelog');
      $top->child(Account => url => '/account');

      Jifty->web->session->expires( '+1y' );
};

on '/admin/created-changelog' => run {
    my $id = Jifty->web->response->result('create-changelog')->content('id');
    my $admin_token = Changelog($id)->as_superuser->admin_token;
    redirect "/admin/changelog/changes/$admin_token";
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
on qr{^/admin/changelog((?:/[^/]+)*)/([^/]+)$} => run {
    my ($subpage, $uuid) = ($1, $2);

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

    add_export_format_nav($cl->name);

    set id => $cl->id;
    show "/admin/changelog$subpage";
};

before '/account' => sub {
    my $account = Jifty->web->navigation->child('Account');
    $account->child(
        Votes => url => "/account/votes",
    );
};

sub add_export_format_nav {
    my $name = shift;

    my $changelog = Jifty->web->navigation->child(
        $name  => url => "/changelog/$name",
        active => 1,
    );

    my @output_formats = map { s/.*:://; $_ } App::Changeloggr->output_formats;

    for my $format_name (@output_formats) {
        $changelog->child(
            "Export as $format_name" =>
            url => "/changelog/$name/$format_name/Changes",
        );
    }
}

1;

