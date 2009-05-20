package App::Changeloggr::Dispatcher;
use Jifty::Dispatcher -base;
use JiftyX::ModelHelpers;

before '*' => run {
      my $top = Jifty->web->navigation;
      $top->child(Home => url => '/');
      $top->child(New => url => '/admin/create-changelog', label => 'New Changelog');
      $top->child(Account => url => '/account');

      Jifty->web->session->expires( '+1y' );

      my $session = Jifty->web->session->id
          or return;
      my $user = App::Changeloggr::Model::User->new;
      $user->load_or_create(session_id => $session);
      Jifty->web->current_user->user_object($user);
};

on '/admin/created-changelog' => run {
    my $id = Jifty->web->response->result('create-changelog')->content('id');
    my $admin_token = Changelog($id)->as_superuser->admin_token;
    redirect "/admin/changelog/changes/$admin_token";
};

before '/changelog/*' => run {
    warn "Checking before $1";
    my $cl = Changelog( name => $1 );
    warn "cl is $cl id ".$cl->id;
    return unless $cl->id and $cl->current_user_is_admin;
    Jifty->web->navigation->child(
        "Administrate" => url => "/admin/changelog/" . $cl->admin_token,
    );
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

    add_export_format_nav($admin);

    # make this user an admin for this changelog
    my $changelog_admin = App::Changeloggr::Model::ChangelogAdmin->new(current_user => App::Changeloggr::CurrentUser->superuser);
    $changelog_admin->load_or_create(
        changelog_id => $cl->id,
        user_id      => Jifty->web->current_user->id,
    );

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
    my $parent = shift;

    my @output_formats = map { s/.*:://; $_ } App::Changeloggr->output_formats;

    for my $format_name (@output_formats) {
        $parent->child(
            "Export as $format_name" =>
            url => "/changelog/$name/$format_name/Changes",
        );
    }
}

1;

