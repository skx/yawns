#
# This is a CGI::Application class which is designed to handle
# our main site.
#
#


use strict;
use warnings;


#
# Hierarchy.
#
package Application::Yawns;
use base 'CGI::Application';


#
# Standard module(s)
#
use Cache::Memcached;
use HTML::Template;
use Digest::MD5 qw! md5_hex !;

#
# Our code
#
use Yawns::About;
use Yawns::Articles;
use Yawns::Cache;
use Yawns::Event;
use Yawns::Sidebar;
use Yawns::User;
use conf::SiteConfig;


=begin doc

Setup - Instantiate the session and handle cookies.

=end doc

=cut

sub cgiapp_init
{
    my $self  = shift;
    my $query = $self->query();

    my $cookie_name   = 'CGISESSID';
    my $cookie_expiry = '+7d';
    my $sid           = $query->cookie($cookie_name) || undef;

    #
    # The memcached host is the same as the DBI host.
    #
    my $dbserv = conf::SiteConfig::get_conf('dbserv');
    $dbserv .= ":11211";

    #
    # Get the memcached handle.
    #
    my $mem = Cache::Memcached->new( { servers => [$dbserv],
                                       debug   => 0
                                     } );

    # session setup
    my $session =
      new CGI::Session( "driver:memcached", $query, { Memcached => $mem } ) or
      die($CGI::Session::errstr);



    # assign the session object to a param
    $self->param( session => $session );

    # send a cookie if needed
    if ( !defined $sid or $sid ne $session->id )
    {
        my $cookie = $query->cookie( -name     => $cookie_name,
                                     -value    => $session->id,
                                     -expires  => $cookie_expiry,
                                     -httponly => 1,
                                   );
        $self->header_props( -cookie => $cookie );
    }


    binmode STDIN,  ":encoding(utf8)";
    binmode STDOUT, ":encoding(utf8)";
}


#
#  Prerun - Validate login requirements, if any
#
sub cgiapp_prerun
{
    my $self = shift;

    my $session = $self->param("session");

    if ( $session && $session->param("suspended") )
    {

        #
        #  Get the current run-mode, we want to allow
        # access to /logout/
        #
        my $cur = $self->get_current_runmode();
        if ( $cur !~ /logout$/i )
        {
            my $query = $self->query();
            $query->param( "about", "suspended" );
            $self->prerun_mode('about');
            return;
        }
    }

    if ( $session && $session->param("ssl") )
    {

        #
        #  If we're not over SSL then abort
        #
        if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
        {

            # NOP
        }
        else
        {
            return (
                  $self->redirectURL(
                      "https://" . $ENV{ "SERVER_NAME" } . $ENV{ 'REQUEST_URI' }
                  ) );
        }
    }

    if ( $session && $session->param("ip") )
    {

        #
        #  Test IP
        #
        my $cur = $ENV{ 'REMOTE_ADDR' };
        my $old = $session->param("ip");

        if ( $cur ne $old )
        {
            print <<EOF;
Content-type: text/html


IP changed - session dropped.
EOF
        }
    }
}



#
#  Flush the sesions
#
sub teardown
{
    my ($self) = shift;

    my $session = $self->param('session');
    $session->flush() if ( defined($session) );
}


=begin doc

Called when an unknown mode is encountered.

=end doc

=cut

sub unknown_mode
{
    my ( $self, $requested ) = (@_);

    $requested =~ s/<>/_/g;

    return ("mode not found $requested");
}




=begin doc

Setup our run-mode mappings, and the defaults for the application.

=end doc

=cut

sub setup
{
    my $self = shift;

    $self->error_mode('my_error_rm');
    $self->run_modes(

        # Front-page
        'index' => 'index',

        # Past artciles
        'archive' => 'archive',

        # static pages
        'about'      => 'about_page',
        'edit_about' => 'edit_about',

        # scratch-pad support
        'scratchpad'      => 'scratchpad',
        'edit_scratchpad' => 'edit_scratchpad',

        # Bookmark support
        'view_bookmarks'  => 'view_bookmarks',
        'delete_bookmark' => 'delete_bookmark',

        # debug
        'debug' => 'debug',

        # Adverts
        'follow_advert'    => 'follow_advert',
        'advert_stats'     => 'advert_stats',
        'edit_adverts'     => 'edit_adverts',
        'view_all_adverts' => 'view_all_adverts',
        'enable_advert'    => 'enable_advert',
        'disable_advert'   => 'disable_advert',
        'delete_advert'    => 'delete_advert',
        'adverts_byuser'   => 'adverts_byuser',

        # Administrivia
        'recent_users' => 'recent_users',

        # Login/Logout
        'login'  => 'application_login',
        'logout' => 'application_logout',

        # Tag operations
        'tag_cloud'  => 'tag_cloud',
        'tag_search' => 'tag_search',

        # View an article
        'article'         => 'article',
        'article_wrapper' => 'article_wrapper',

        # Weblogs
        'weblog'        => 'weblog',
        'single_weblog' => 'single_weblog',


        # Searching
        'article_search' => 'article_search',

        # Hall of fame
        'hof' => 'hof',

        # called on unknown mode.
        'AUTOLOAD' => 'unknown_mode',
    );

    #
    #  Start mode + mode name
    #
    $self->header_add( -charset => 'utf-8' );
    $self->start_mode('index');
    $self->mode_param('mode');

}




#
#  Error-mode.
#
sub my_error_rm
{
    my ( $self, $error ) = (@_);

    use Data::Dumper;
    return Dumper( \$error );
}



=begin doc

Redirect to the given URL.

=end doc

=cut

sub redirectURL
{
    my ( $self, $url, $status ) = (@_);

    $status = 302 unless ( $status && ( $status =~ /^([0-9]+)$/ ) );

    #
    #  Cookie name & expiry
    #
    my $cookie_name   = 'CGISESSID';
    my $cookie_expiry = '+7d';

    #
    #  Get the session identifier
    #
    my $query   = $self->query();
    my $session = $self->param('session');

    my $id = "";
    $id = $session->id() if ($session);

    #
    #  Create/Get the cookie
    #
    my $cookie = $query->cookie( -name    => $cookie_name,
                                 -value   => $id,
                                 -expires => $cookie_expiry,
                               );

    $self->header_add( -location => $url,
                       -status   => $status,
                       -cookie   => $cookie
                     );
    $self->header_type('redirect');
    return "";

}




=begin doc

  A filter to allow dynamic page inclusions.

=end doc

=cut

sub mk_include_filter
{
    my $page = shift;
    return sub {
        my $text_ref = shift;
        $$text_ref =~ s/###/$page/g;
    };
}



=begin doc

  Load a layout and a page snippet with it.

=end doc

=cut

sub load_layout
{
    my ( $self, $page, %options ) = (@_);

    #
    #  Make sure the snippet exists.
    #
    if ( -e "../templates/pages/$page" )
    {
        $page = "../templates/pages/$page";
    }
    else
    {
        die "Page not found: $page";
    }

    #
    #  Load our layout.
    #
    #
    #  TODO: Parametize:
    #
    my $layout = "../templates/layouts/default.template";
    my $l = HTML::Template->new( filename => $layout,
                                 %options,
                                 filter => mk_include_filter($page) );

    #
    #  IPv6 ?
    #
    if ( $ENV{ 'REMOTE_ADDR' } =~ /:/ )
    {
        $l->param( ipv6 => 1 ) unless ( $ENV{ 'REMOTE_ADDR' } =~ /^::ffff:/ );
    }

    #
    #  If we're supposed to setup a session token for a FORM element
    # then do so here.
    #
    my $session = $self->param("session");
    if ( $options{ 'session' } )
    {
        delete $options{ 'session' };
        $l->param( session => md5_hex( $session->id() ) );
    }

    #
    # Make sure the sidebar text is setup.
    #
    my $sidebar = Yawns::Sidebar->new();
    $l->param(
            sidebar_text => $sidebar->getMenu( $session->param("logged_in") ) );
    $l->param(
         login_box_text => $sidebar->getLoginBox( $session->param("logged_in") )
    );
    $l->param( site_title => get_conf('site_title') );
    $l->param( metadata   => get_conf('metadata') );

    my $logged_in = 1;

    my $username = $session->param("logged_in");
    if ( $username =~ /^anonymous$/i )
    {
        $logged_in = 0;
    }
    $l->param( logged_in => $logged_in );

    return ($l);
}



# ===========================================================================
# CSRF protection.
# ===========================================================================
sub validateSession
{
    my ($self) = (@_);

    my $session = $self->param("session");

    #
    #  We cannot validate a session if we have no cookie.
    #
    my $username = $session->param("logged_in") || "Anonymous";
    return 0 if ( !defined($username) || ( $username =~ /^anonymous$/i ) );

    my $form = $self->query();

    # This is the session token we're expecting.
    my $wanted = md5_hex( $session->id() );

    # The session token we recieved.
    my $got = $form->param("session");

    if ( ( !defined($got) ) || ( $got ne $wanted ) )
    {
        return 1;
    }

    return 0;
}


# ===========================================================================
# Permission Denied - or other status message
# ===========================================================================
sub permission_denied
{
    my ( $self, %parameters ) = (@_);

    # set up the HTML template
    my $template = $self->load_layout("permission_denied.inc");

    # title
    my $title = $parameters{ 'title' } || "Permission Denied";
    $template->param( title => $title );

    #
    # If we got a custom option then set that up.
    #
    if ( scalar( keys(%parameters) ) )
    {
        $template->param(%parameters);
        $template->param( custom_error => 1 );
    }

    # generate the output
    return ( $template->output() );
}


#
#  Real handlers
#


#
#  Handlers
#
sub debug
{
    my ($self) = (@_);

    my $session = $self->param('session');
    my $username = $session->param("logged_in") || "Anonymous";

    return ("OK - $username");
}



#
#  Login
#
sub application_login
{
    my ($self) = (@_);

    my $q       = $self->query();
    my $session = $self->param('session');

    # if already logged in redirect
    my $username = $session->param("username") || undef;
    if ( $username && ( $username ne "Anonymous" ) )
    {
        return $self->redirectURL("/");
    }

    #
    # If the user isn't submitting a form then show it
    #
    if ( !$q->param("submit") )
    {


        # open the html template
        my $template = $self->load_layout("login_form.inc");

        if ( !defined( $ENV{ 'HTTPS' } ) or ( $ENV{ 'HTTPS' } !~ /on/i ) )
        {

            # Link to the HTTPS version of this form
            $template->param( http => 1 );

            # Secure link
            $template->param( secure => "https://" . $ENV{ 'SERVER_NAME' } .
                                $ENV{ 'REQUEST_URI' },
                              title => "Advanced Login Options"
                            );
        }

        return ( $template->output() );
    }


    my $lname  = $q->param('lname');
    my $lpass  = $q->param('lpass');
    my $secure = $q->param('secure');
    my $ssl    = $q->param('ssl');


    my $protocol = "http://";

    if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
    {
        $protocol = "https://";
    }

    #
    # Login results.
    #
    my ( $logged_in, $suspended ) = undef;

    #
    # Do the login
    #
    my $user = Yawns::User->new();
    ( $logged_in, $suspended ) =
      $user->login( username => $lname,
                    password => $lpass );

    #
    #  If it worked
    #
    if ( ($logged_in) and ( !( lc($logged_in) eq lc('Anonymous') ) ) )
    {

        my $event = Yawns::Event->new();
        my $link  = $protocol . $ENV{ "SERVER_NAME" } . "/users/$logged_in";
        $event->send(
                 "Successful login for <a href=\"$link\">$logged_in</a> from " .
                   $ENV{ 'REMOTE_ADDR' } );

        #
        #  Setup the session variables.
        #
        $session->param( "logged_in",    $logged_in );
        $session->param( "failed_login", undef );
        $session->param( "suspended",    $suspended ) if $suspended;

        #
        #  If the user wanted a secure login bind their cookie to the
        # remote address.
        #
        if ( defined($secure) && ($secure) )
        {
            $session->param( "session_ip", $ENV{ 'REMOTE_ADDR' } );
        }
        else
        {
            $session->param( "session_ip", undef );
        }

        #
        #  If the user wanted SSL all the time then set it up
        #
        if ( defined($ssl) && ($ssl) )
        {
            $session->param( "ssl", 1 );
        }
        else
        {
            $session->param( "ssl", undef );
        }

        #
        # Login succeeded.  If we have a redirection target:
        #
        # 1:  Close session.
        # 2:  Redirect + Set-Cookie
        # 3:  Exit.
        #
        my $target = $q->param("target");
        if ( defined($target) && ( $target =~ /^\// ) )
        {
            return ( $self->redirectURL($target) );
        }
        else
        {

            #
            #  No explicit target - show the homepage.
            #
            return ( $self->redirectURL("/") );
        }
    }
    else
    {

        my $event = Yawns::Event->new();
        $lname = "_unknown_" if ( !defined($lname) );
        $event->send( "Failed login for $lname from " . $ENV{ 'REMOTE_ADDR' } );

        #
        # Login failed:  Invalid username or wrong password.
        #
        $session->param( "failed_login", 1 );
        return ( $self->redirectURL("/login/") );
    }

}


#
# Logout the user.
#
sub application_logout
{
    my ($self) = (@_);

    my $q       = $self->query();
    my $session = $self->param('session');

    #
    #  Clear the session
    #
    $session->param( 'logged_in', undef );
    $session->clear('logged_in');

    $session->param( 'suspended', undef );
    $session->clear('suspended');

    $self->param( 'session', undef );
    $session->flush();
    $session->close();

    #
    #  Return to the homepage - no cookie
    #
    $self->header_add( -location => "/",
                       -status   => "302", );
    $self->header_type('redirect');
    return "";
}



# ===========================================================================
# Show year-based archives of articles.
# ===========================================================================
sub archive
{
    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form    = $self->query();
    my $session = $self->param("session");

    #
    #  Get the current month and year.
    #
    my $year = undef;
    $year = $form->param('year') if $form->param('year');


    #
    #  Get the current year
    #
    my ( $sec, $min, $hour, $mday, $mon, $yr, $wday, $yday, $isdst );
    ( $sec, $min, $hour, $mday, $mon, $yr, $wday, $yday, $isdst ) =
      localtime(time);

    my $current_year = $yr + 1900;


    #
    #  If there is no year then the year is this one.
    #
    if ( !defined($year) )
    {
        $year = $current_year;
    }

    #
    # get required articles from database
    #
    my $articles     = Yawns::Articles->new();
    my %years        = $articles->getArticleYears();
    my $the_articles = $articles->getArchivedArticles($year);

    my $years;
    foreach my $y ( reverse sort keys %years )
    {
        push( @$years, { year => $y } );
    }

    #
    # Load the display template.
    #
    my $template = $self->load_layout("archive.inc");

    #
    #  Articles.
    #
    $template->param( articles          => $the_articles ) if $the_articles;
    $template->param( show_archive_year => $years )        if ($years);

    my $title = "Archive for $year";

    #
    #  Show the month name, and the currently viewed year.
    #
    $template->param( year  => $year,
                      title => $title );


    # generate the output
    return ( $template->output() );
}




# ===========================================================================
# about section
# ===========================================================================
sub about_page
{
    my ($self) = (@_);

    my $q        = $self->query();
    my $session  = $self->param('session');
    my $username = $session->param("logged_in") || "Anonymous";

    #
    # Is the viewer allowed to edit the page?
    #
    my $may_edit = 0;
    if ( $username !~ /^anonymous$/ )
    {

        #
        #  Check the permissions
        #
        my $perms = Yawns::Permissions->new( username => $username );
        $may_edit = 1 if $perms->check( priv => "edit_about" );
    }


    #
    # Get the page from the about section.
    #
    my $key   = $q->param('about');
    my $pages = Yawns::About->new();
    my $about = $pages->get( name => $key );


    # set up the HTML template
    my $template = $self->load_layout("about.inc");

    # fill in the template parameters
    $template->param( title        => $key,
                      article_body => $about,
                      may_edit     => $may_edit,
                    );

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# Show tags.
# ===========================================================================
sub tag_cloud
{
    my ($self) = (@_);

    #
    # Get the tags.
    #
    my $tags   = Yawns::Tags->new();
    my $all    = $tags->getAllTags();
    my $recent = $tags->getRecent();


    # read in the template file
    my $template = $self->load_layout("tag_view.inc");

    #
    #  Title
    #
    $template->param( title => "Tag Cloud" );

    #
    #  Actual Tags
    #
    $template->param( all_tags => $all ) if ($all);

    #
    #  Recent tags.
    #
    $template->param( recent_tags => $recent ) if ($recent);

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
#  Search for things by tag.
# ===========================================================================
sub tag_search
{
    my ($self) = (@_);

    #
    # Get the tag we're looking for
    #
    my $form = $self->query();
    my $tag  = $form->param("tag");

    #
    #  Do the search
    #
    my $tags = Yawns::Tags->new();
    my ( $articles, $polls, $submissions, $weblogs ) = $tags->findByTag($tag);
    my $recent  = $tags->getRecent();
    my $related = $tags->getRelatedTags($tag);


    # set up the HTML template
    my $template =
      $self->load_layout( "tag_search_results.inc", loop_context_vars => 1 );

    #
    # fill in the template parameters
    #
    $template->param( articles     => $articles )    if ($articles);
    $template->param( polls        => $polls )       if ($polls);
    $template->param( submissions  => $submissions ) if ($submissions);
    $template->param( weblogs      => $weblogs )     if ($weblogs);
    $template->param( tag          => $tag );
    $template->param( related_tags => $related )     if ($related);

    # Error?
    if ( ( !$articles ) &&
         ( !$polls ) &&
         ( !$submissions ) &&
         ( !$weblogs ) )
    {
        $template->param( empty => 1 );
    }

    #
    #  Recent tags.
    #
    $template->param( recent_tags => $recent ) if ($recent);
    $template->param( title => "Tag search results for: $tag" );

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# Search past articles
# ===========================================================================
sub article_search
{
    my ($self) = (@_);

    #
    #  Gain access to the things we require.
    #
    my $form = $self->query();

    #
    #  Get the search term(s)
    #
    my $terms = $form->param("q") || undef;
    my $template = $self->load_layout("search_articles.inc");

    if ($terms)
    {
        use Lucy::Simple;

        my $lucy = Lucy::Simple->new( path     => "/tmp/index",
                                      language => 'en' );


        my $hits = $lucy->search( query      => $terms,
                                  offset     => 0,
                                  num_wanted => 50,
                                );

        my $results;

        while ( my $hit = $lucy->next )
        {
            push( @$results, { id => $hit->{ id }, title => $hit->{ title } } );
        }
        $template->param( terms => $terms );
        $template->param( results => $results ) if ($results);
    }
    return ( $template->output() );
}


# ===========================================================================
# Edit About pages
# ===========================================================================
sub edit_about
{
    my ($self) = (@_);

    my $session  = $self->param("session");
    my $username = $session->param("logged_in");

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "edit_about" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    # Get access to the form and database
    my $form = $self->query();

    # load the template
    my $template = $self->load_layout( "edit_about.inc", session => 1 );

    #
    # Are we viewing a page, or the picker?
    #
    my $action = $form->param('page') || "";

    if ( $action eq 'pick' )
    {

        # Get the page options.
        my $aboutPages = Yawns::About->new();

        # build the select list of possible pages
        $template->param( about_pages => $aboutPages->get() );
        return ( $template->output() );
    }


    #
    #  Are we saving?
    #
    if ( $form->param("submit") )
    {

        # validate session.
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        my $old_page = $form->param('pagename');
        my $new_page = $form->param('pageid');
        my $body     = $form->param('bodytext');

        #
        # Update the page
        #
        my $aboutPages = Yawns::About->new();

        #
        # Delete the old page.
        #
        # (Note this might be the same as the 'new' page.
        #
        $aboutPages->delete( name => $old_page );

        #
        # Now set the new text.
        #
        $aboutPages->set( name => $new_page,
                          text => $body );

        # build the select list of possible pages and set confirmation
        $template->param( about_pages => $aboutPages->get(),
                          confirm     => 1,
                          page        => $new_page,
                          title       => "Page Saved: $new_page",
                        );
    }
    else
    {
        my $about = Yawns::About->new();
        my $page = $form->param('page') || '';

        #
        #  Get the page.
        #
        my $body = $about->get( name => $page ) if defined($page);


        #
        #  Ensure entities are escaped.
        #
        $body = HTML::Entities::encode_entities($body);

        #
        #  Setup display.
        #
        $template->param( id         => $page,
                          about_body => $body,
                          title      => "Edit About: $page",
                        );
    }

    # generate the output
    return ( $template->output() );
}



##
#
#  This function is a mess.
#
#  It must allow the user to step through the articles on the front-page
# either by section, or just globally.
#
##
sub index
{
    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";


    #
    # Gain access to the articles
    #
    my $articles = Yawns::Articles->new();

    #
    # Get the last article number.
    #
    my $last = $articles->count();
    $last += 1;

    #
    # How many do we show on the front page?
    #
    my $count = get_conf('headlines');

    #
    # Get the starting (maximum) number of the articles to view.
    #
    my $start = $last;
    $start = $form->param('start') if $form->param('start');
    if ( $start =~ /([0-9]+)/ )
    {
        $start = $1;
    }

    $start = $last if ( $start > $last );

    #
    # get required articles from database
    #
    my ( $the_articles, $last_id ) = $articles->getArticles( $start, $count );

    $last_id = 0 unless $last_id;


    #
    # Data for pagination
    #
    my $shownext  = 0;
    my $nextfrom  = 0;
    my $nextcount = 0;

    my $showprev  = 0;
    my $prevfrom  = 0;
    my $prevcount = 0;


    $nextfrom = $start + 10;
    if ( $nextfrom > $last ) {$nextfrom = $last;}

    $nextcount = 10;
    if ( $nextfrom + 10 > $last ) {$nextcount = $last - $start;}
    while ( $nextcount > 10 )
    {
        $nextcount -= 10;
    }

    $prevfrom = $last_id - 1;
    if ( $prevfrom < 0 ) {$prevfrom = 0;}

    $prevcount = 10;
    if ( $prevfrom - 10 < 0 ) {$prevcount = $start - 11;}

    if ( $start < $last )
    {
        $shownext = 1;
    }
    if ( $start > 10 )
    {
        $showprev = 1;
    }

    # read in the template file
    my $template = $self->load_layout( "index.inc", loop_context_vars => 1 );


    # fill in all the parameters we got from the database
    if ($last_id)
    {
        $template->param( articles => $the_articles );
    }


    $template->param( shownext  => $shownext,
                      nextfrom  => $nextfrom,
                      nextcount => $nextcount,
                      showprev  => $showprev,
                      prevfrom  => $prevfrom,
                      prevcount => $prevcount,
                      content   => $last_id,
                    );

    #
    #  Add in the tips
    #
    my $weblogs     = Yawns::Weblogs->new();
    my $recent_tips = $weblogs->getTipEntries();
    $template->param( recent_tips => $recent_tips ) if ($recent_tips);


    # generate the output
    return ( $template->output() );
}


# ===========================================================================
# Articles should have consistent URLs.
# ===========================================================================
sub article_wrapper
{
    my ($self) = (@_);

    my $form = $self->query();
    my $id   = $form->param("id");
    my $tit  = $form->param("title");

    if ( ($id) && ( $id =~ /^([0-9]+)$/ ) )
    {

        #
        #
        #
        my $art = Yawns::Article->new( id => $id );
        my $title = $art->getTitle();

        my $articles = Yawns::Articles->new();
        my $slug     = $articles->makeSlug($title);


        return ( $self->redirectURL("/article/$id/$slug") );

    }
    elsif ($tit)
    {

        #
        #  Find the article by the title
        #
        my $articles = Yawns::Articles->new();
        my $id = $articles->findBySlug( slug => $tit );

        if ( defined($id) &&
             length($id) &&
             ( $id =~ /^([0-9]+)$/ ) )
        {

            my $art = Yawns::Article->new( id => $id );
            my $title = $art->getTitle();

            my $articles = Yawns::Articles->new();
            my $slug     = $articles->makeSlug($title);

            return ( $self->redirectURL("/article/$id/$slug") );

        }
    }
    return "Invalid ID/title - $id - $tit";
}




# ===========================================================================
# Read an article
# ===========================================================================
sub article
{
    my ($self) = (@_);

    #
    # Get singleton objects we care about
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    # Get article number from URL
    #
    my $article_id = $form->param('id') if defined $form->param('id');

    #
    # Ensure article only contains numerical digits.
    #
    if ( $article_id =~ /([0-9]+)/ )
    {
        $article_id = $1;
    }


    #
    # If we're not logged in then undef this so that the templates
    # don't show adverts.
    #
    my $logged_in = 1;
    if ( $username =~ /^anonymous$/i )
    {
        $logged_in = 0;
    }


    #
    # See if the user has altruisticly decided to show adverts
    #
    my $show_adverts   = 1;
    my $google_adverts = 0;
    my $user_adverts   = 0;

    #
    #  Anonymous users always get adverts.
    #
    if ( $username =~ /^anonymous$/i )
    {
        $show_adverts = 1;
    }
    else
    {

        #
        #  Other users do not, unless they have set such an option
        # manually.
        #
        my $user = Yawns::User->new( username => $username );
        my $user_data = $user->get();
        $show_adverts = $user_data->{ 'viewadverts' };
    }


    #
    #  If we're showing adverts then choose the type randomly.
    #
    if ($show_adverts)
    {
        my $rnd = int( rand(100) );

        if ( $rnd <= 10 )
        {
            $user_adverts = 1;
        }
        else
        {
            $google_adverts = 1;
        }
    }

    my $template = $self->load_layout( "view_article.inc",
                                       loop_context_vars => 1,
                                       global_vars       => 1,
                                       session           => 1
                                     );

    #
    # Get the appropriate article from database
    #
    my $accessor = Yawns::Article->new( id => $article_id );
    my $article = $accessor->get();

    my $tagHolder = Yawns::Tags->new();
    my $tags = $tagHolder->getTags( article => $article_id );
    if ( defined($tags) )
    {
        $template->param( tags => $tags );
    }


    #
    #  Does the article exist?
    #
    my $error = 0;
    if ( !defined( $article->{ article_body } ) )
    {
        $error = 1;
    }


    #
    # Cleanup article body if it is defined.
    #
    if ( !$error )
    {
        $article->{ 'article_body' } =~ s/&amp;#13;//g;
        $article->{ 'article_body' } =~ s/&amp;quot;/"/g;
        $article->{ 'article_body' } =~ s/&amp;amp;/&/g;
        $article->{ 'article_body' } =~ s/&amp;lt;/&lt;/g;
        $article->{ 'article_body' } =~ s/&amp;gt;/&gt;/g;
    }


    #
    # Article author can see article read count, and have
    # a link to edit the article.
    #
    my $article_author = undef;
    my $author         = $article->{ 'article_byuser' };

    if ( defined($username) &&
         ( !( $username =~ /anonymous/i ) ) &&
         defined($author) &&
         ( lc($username) eq lc($author) ) )
    {
        $article_author = 1;
    }

    #
    #  Show the admin linke?
    #
    my $show_admin_links = 0;
    if ($logged_in)
    {
        my $perms = Yawns::Permissions->new( username => $username );
        $show_admin_links = 1 if ( $perms->check( priv => "article_admin" ) );
    }



    #
    #  Get related links.
    #
    my $related = $accessor->getRelated();

    #
    #  If we're supposed to be showing user-adverts then
    # display one at random.
    #
    if ($user_adverts)
    {
        my $adverts = Yawns::Adverts->new();
        if ( $adverts->countActive() )
        {
            my $data = $adverts->fetchRandomAdvert();

            $template->param( advert_id        => $data->{ 'id' },
                              advert_link_text => $data->{ 'linktext' },
                              advert_link      => $data->{ 'link' },
                              advert_text      => $data->{ 'text' } );
        }
        else
        {

            #
            #  We're supposed to show a user advert, but there aren't
            # any.
            #
            $google_adverts = 1;
            $user_adverts   = 0;
        }
    }


    #
    #  Tag addition URL
    #
    $template->param( tag_url => "/ajax/addtag/$article_id/" );

    my $a = Yawns::Articles->new();

    my $slug = $a->makeSlug( $article->{ 'article_title' } || "" );

    # fill in all the parameters you got from the database
    $template->param(
        article_id     => $article_id,
        article_title  => $article->{ 'article_title' },
#        slug           => $slug,
        title          => $article->{ 'article_title' },
        suspended      => $article->{ 'suspended' },
        article_byuser => $article->{ 'article_byuser' },
        article_ondate => $article->{ 'article_ondate' },
        article_attime => $article->{ 'article_attime' },
        article_body   => $article->{ 'article_body' },
        comments       => $article->{ 'comments' },
        logged_in      => $logged_in,
        show_adverts   => $show_adverts,
        google_adverts => $google_adverts,
        user_adverts   => $user_adverts,
        error          => $error,
        article_author => $article_author,
        article_admin  => $show_admin_links,
        related        => $related,

        # Navigation to previous article
        showprev        => $article->{ 'prev_show' },
        prevarticleslug => $a->makeSlug( $article->{ 'prevarticle' } || "" ),
        prevarticle     => $article->{ 'prevarticle' },
        prev            => $article->{ 'prev' },

        # Navigation to next article
        shownext        => $article->{ 'next_show' },
        nextarticleslug => $a->makeSlug( $article->{ 'nextarticle' } || "" ),
        nextarticle     => $article->{ 'nextarticle' },
        next            => $article->{ 'next' },
                    );


    $template->param(
                 canon => get_conf("home_url") . "/article/$article_id/$slug" );


    # ----- now do the comments section -----
    my $comments_exist = $article->{ 'comments' };
    if ($comments_exist)
    {
        my $templateC =
          HTML::Template->new(
                          filename => "../templates/includes/comments.template",
                          global_vars => 1 );

        my $ses = Singleton::Session->instance();
        $templateC->param( session => md5_hex( $ses->id() ) );


        my $comments = Yawns::Comments->new( article => $article_id );

        #
        #  Only show comments if found.
        #
        my $found = $comments->get();
        $templateC->param( comments => $found ) if ($found);

        # generate the output
        my $comment_text = $templateC->output();
        $template->param( comment_text => $comment_text );
    }

    #
    # generate the output
    #
    return ( $template->output() );
}




# ===========================================================================
# View a single weblog entry.
# ===========================================================================
sub single_weblog
{
    my ($self) = (@_);

    #
    # Gain acess to the objects we use.
    #
    my $form      = $self->query();
    my $session   = $self->param("session");
    my $username  = $session->param("logged_in") || "Anonymous";
    my $logged_in = 1;

    my $comment_count;
    if ( $username =~ /^anonymous$/i )
    {
        $logged_in = 0;
    }

    # get username from URL and the id of the entry we're viewing.
    my $viewusername = $form->param('show');
    my $id           = $form->param('item');
    my $error        = 0;


    # in the case an entry has been deleted we want to
    # link to next/prev
    my $error_prev;
    my $error_next;

    #
    #  Users can edit their own entries, and see the read count.
    #
    my $edit = 0;
    my $read = 0;
    if ( lc($viewusername) eq lc($username) )
    {
        $edit = 1;
    }


    #
    #  Get weblog entries, or entry.
    # (If item is defined that's the specific one we want to view).
    #
    #
    my $weblog = Yawns::Weblog->new( username => $viewusername );
    my $gid = $weblog->getGID( username => $viewusername,
                               id       => $id );


    my $entries;

    if ($gid)
    {
        $entries =
          $weblog->getSingleWeblogEntry( gid      => $gid,
                                         editable => $edit );
    }
    else
    {

        # GID not found - most likely an invalid weblog entry.
        $error = 1;

        my $max = $weblog->count();

        if ( $id > 0 )
        {
            $error_prev = $id - 1;
        }
        if ( $id <= $max )
        {
            $error_next = $id + 1;
        }
    }

    #
    # Open the html template
    #
    my $template = $self->load_layout( "single_weblog.inc",
                                       loop_context_vars => 1,
                                       global_vars       => 1,
                                       session           => 1
                                     );

    #
    #  Can this entry be reported?
    #
    if ( ($logged_in) && ( !$edit ) )
    {

        #
        #  It is pointless to be reportable if it has been hidden completely.
        #
        #  Or if it doesnt' exist.
        #
        if ( ( !$error ) &&
             ( $weblog->getScore( gid => $gid ) > 0 ) &&
             ( !$session->param( "reported_" . $gid ) ) )

        {
            $template->param( reportable => 1 );
        }
    }
    if ( not defined(@$entries) )
    {
        $error = 1;

    }

    if ( $error == 0 )
    {
        my $enabled = @$entries[0]->{ 'comments_enabled' };
        $comment_count = $weblog->getCommentCount( gid => $gid );

        if ($comment_count)
        {
            my $templateC =
              HTML::Template->new(
                          filename => "../templates/includes/comments.template",
                          global_vars => 1 );

            my $sess = Singleton::Session->instance();
            $templateC->param( session => md5_hex( $sess->id() ) );

            my $comments =
              Yawns::Comments->new( weblog  => $gid,
                                    enabled => $enabled );

            #
            my $com = $comments->get();
            $templateC->param( comments => $com ) if ($com);

            # generate the output
            my $comment_text = $templateC->output();
            $template->param( comment_text => $comment_text )
              if ($comment_text);
        }
    }

    #
    #  Some items are used for the title.
    #
    my $title = '';

    my $body = undef;
    if ( defined( @$entries[0] ) )
    {
        my $weblog_owner = @$entries[0]->{ 'user' };
        my $weblog_title = @$entries[0]->{ 'title' };
        $body = @$entries[0]->{ 'bodytext' };

        if ( defined($weblog_owner) &&
             length($weblog_owner) &&
             defined($weblog_title) &&
             length($weblog_title) )
        {
            $title = "Weblog for " . $weblog_owner . " - " . $weblog_title;
        }
    }
    else
    {
        $error = 1;
    }

    #
    #  Per-article adverts?
    #
    my $show_adverts = 1;
    if ( $username =~ /^anonymous$/i )
    {
        $show_adverts = 1;
    }
    else
    {

        #
        #  Other users do not, unless they have set such an option
        # manually.
        #
        my $user = Yawns::User->new( username => $username );
        my $user_data = $user->get();
        $show_adverts = $user_data->{ 'viewadverts' };
    }


    #
    #  Tag addition URL
    #
    $template->param( tag_url => "/ajax/addtag/weblog/$gid/" );

    # set parameters
    $template->param( entries       => $entries,
                      error         => $error,
                      error_next    => $error_next,
                      error_prev    => $error_prev,
                      user          => $viewusername,
                      title         => $title,
                      comment_count => $comment_count,
                      item          => $id,
                    );

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# View weblog entries by a user.
# ===========================================================================
sub weblog
{
    my ($self) = (@_);

    #
    # Gain acess to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";


    # get username from URL and the starting entry to show, if any.
    my $viewusername = $form->param('show');
    my $start = $form->param('start') || undef;

    #
    # If the user is viewing their own weblog they can edit it.
    #
    my $is_owner = 0;
    my $anon = 1 if ( $username =~ /^anonymous$/i );

    if ( lc($username) eq lc($viewusername) )
    {
        $is_owner = 1 unless ($anon);
    }

    #
    # Open the html template
    #
    my $template = $self->load_layout("user_weblog.inc");

    #
    # Get the weblog entries, and insert them into the output.
    #
    my $weblog = Yawns::Weblog->new( username => $viewusername );
    my $entries = $weblog->getEntries( start => $start );
    my $count = $weblog->count();


    $start = $count if ( !defined($start) );
    my $show_prev = undef;
    my $show_next = undef;
    if ( $start - 10 > 0 )       {$show_prev = $start - 10;}
    if ( $start + 10 <= $count ) {$show_next = $start + 10;}

    my $title = "Weblogs for " . $viewusername;

    $template->param( title        => $title,
                      viewusername => $viewusername,
                      error        => ( $count == 0 ),
                      show_next    => $show_next,
                      show_prev    => $show_prev,
                      is_owner     => $is_owner,
                    );


    #
    #  Only show the entries if we found them.
    #
    my $c = 0;
    if ( ( $count > 0 ) && defined($entries) && $entries && (@$entries) )
    {
        $c = scalar(@$entries);
    }

    if ( ( defined $entries ) && ( $count > 0 ) && ( $c > 0 ) )
    {
        $template->param( entries => $entries );
    }
    else
    {
        $template->param( error => 1 );
    }

    # generate the output
    return ( $template->output() );
}




# ===========================================================================
# View the site-wide stats page
# ===========================================================================
sub hof
{
    my ($self) = (@_);

    # Get access to the form, session and database handles
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    # get appropriate article from database
    my $hof   = Yawns::Stats->new();
    my $stats = $hof->getStats();

    # helper for making slugs
    my $articles = Yawns::Articles->new();

    # set up the HTML template
    my $template = $self->load_layout("hof.inc");

    # set up the loops
    my $active_articles_ref = $stats->{ 'active_articles' };
    my @active_articles     = @$active_articles_ref;
    my $active_articles     = [];
    my $row;
    foreach $row (@active_articles)
    {
        my @row = @$row;
        my ($ondate) = Yawns::Date::convert_date_to_site( $row[3] );
        push( @$active_articles,
              {  id       => $row[0],
                 title    => $row[1],
                 slug     => $articles->makeSlug( $row[1] ),
                 author   => $row[2],
                 ondate   => $ondate,
                 comments => $row[4],
              } );
    }

    my $longest_articles_ref = $stats->{ 'longest_articles' };
    my @longest_articles     = @$longest_articles_ref;
    my $longest_articles     = [];
    foreach $row (@longest_articles)
    {
        my @row = @$row;
        my ($ondate) = Yawns::Date::convert_date_to_site( $row[3] );
        push( @$longest_articles,
              {  id     => $row[0],
                 title  => $row[1],
                 slug   => $articles->makeSlug( $row[1] ),
                 author => $row[2],
                 ondate => $ondate,
                 words  => $row[4],
              } );
    }



    my $popular_articles_ref = $stats->{ 'popular_articles' };
    my @popular_articles     = @$popular_articles_ref;
    my $popular_articles     = [];

    foreach $row (@popular_articles)
    {
        my @row = @$row;
        my ($ondate) = Yawns::Date::convert_date_to_site( $row[3] );
        push( @$popular_articles,
              {  id        => $row[0],
                 title     => $row[1],
                 slug      => $articles->makeSlug( $row[1] ),
                 author    => $row[2],
                 ondate    => $ondate,
                 readcount => $row[4],
              } );
    }

    # fill in all the parameters
    $template->param( sitename         => get_conf('sitename'),
                      article_count    => $stats->{ 'article_count' },
                      comment_count    => $stats->{ 'comment_count' },
                      user_count       => $stats->{ 'user_count' },
                      weblog_count     => $stats->{ 'weblog_count' },
                      active_articles  => $active_articles,
                      longest_articles => $longest_articles,
                      popular_articles => $popular_articles,
                      title            => "Hall Of Fame",
                    );

    # generate the output
    return ( $template->output() );
}


# ===========================================================================
# View the scratchpad area of a user.
# ===========================================================================
sub scratchpad
{
    my ($self) = (@_);

    #
    # Gain acess to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    my $admin = 0;
    if ( $username !~ /^anonymous$/i )
    {
        my $privs = Yawns::Permissions->new( username => $username );
        $admin = 1 if ( $privs->check( priv => "edit_user_pad" ) );
    }


    my $view = $form->param('user');

    # get the data
    my $scratchpad = Yawns::Scratchpad->new( username => $view );
    my $private    = $scratchpad->isPrivate();
    my $userdata   = $scratchpad->get();

    #
    # Empty data?
    #
    my $empty = 0;
    if ( !defined($userdata) || length($userdata) == 0 )
    {
        $empty = 1;
    }


    # open the html template
    my $template = $self->load_layout("view_scratchpad.inc");

    #
    # Show the edit link?
    #
    my $edit = 0;
    if ( ( ( lc($view) eq lc($username) ) || ($admin) ) &&
         ( $username !~ /^anonymous$/i ) )
    {

        $edit    = 1;
        $private = 0;
    }


    # set parameters
    $template->param( view       => $view,
                      scratchpad => $userdata,
                      edit       => $edit,
                      empty      => $empty,
                      private    => $private,
                      title      => "Viewing Scratchpad for $view",
                    );

    # generate the output
    return ( $template->output() );
}




# ===========================================================================
#  Edit the scratchpad of a user.
# ===========================================================================
sub edit_scratchpad
{
    my ($self) = (@_);

    #
    # Gain acess to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Can we edit this scratchpad?
    #
    my $admin = 0;
    if ( $username !~ /^anonymous$/i )
    {
        my $privs = Yawns::Permissions->new( username => $username );
        $admin = 1 if ( $privs->check( priv => "edit_user_pad" ) );
    }

    #
    #  The user that we're working with.
    #
    my $edituser = $form->param("user");

    #
    # If no username was specified then use the current logged in user.
    #
    if ( ( !defined($edituser) ) || ( $edituser eq 1 ) )
    {
        $edituser = $username;
    }

    #
    #  Anonymous users can't edit.
    #
    if ( $username =~ /^anonymous$/i )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Editting a different user?
    #
    if ( lc($edituser) ne lc($username) )
    {
        if ( !$admin )
        {
            return ( $self->permission_denied( admin_only => 1 ) );
        }
    }


    my $saved = 0;

    #
    # Non-administrators can only edit their own scratchpads.
    #
    if ( !$admin )
    {
        $edituser = $username;
    }

    if ( defined $form->param('save') )
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);


        my $text     = $form->param('text');
        my $security = $form->param('security');

        #
        # Save it.
        #
        my $scratchpad = Yawns::Scratchpad->new( username => $edituser );
        $scratchpad->set( $text, $security );

        $saved = 1;

        #
        #  Flush the cache.
        #
        my $c = Yawns::Cache->new();
        $c->flush("Edit scratchpad for user $edituser");
    }


    # open the html template
    my $template = $self->load_layout( "edit_scratchpad.inc", session => 1 );

    # get the data
    my $scratchpad = Yawns::Scratchpad->new( username => $edituser );
    my $private    = $scratchpad->isPrivate();
    my $userdata   = $scratchpad->get();

    if ($saved)
    {
        $template->param( title => "Scratchpad Updated" );
    }
    else
    {
        $template->param( title => "Edit your scratchpad" );
    }

    # set parameters
    $template->param( username => $edituser,
                      text     => $userdata,
                      saved    => $saved,
                      private  => $private
                    );

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
#  View recently joined usernames
# ===========================================================================
sub recent_users
{
    my ($self) = (@_);

    #
    #  This requires a login
    #
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "recent_users" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    my $form = $self->query();
    my $count = $form->param('recent_users') || 10;
    if ( $count =~ /([0-9]+)/ )
    {
        $count = $1;
    }


    #
    #  Get details.
    #
    my $u     = Yawns::Users->new();
    my $users = $u->getRecent($count);
    my $uc    = scalar(@$users);

    #
    #  Load template
    #
    my $template = $self->load_layout("recent_members.inc");

    $template->param( users => $users,
                      count => $count,
                      title => "Recent Site Members",
                    );
    $template->param( user_count => $uc ) if ( $uc && ( $uc > 0 ) );

    return ( $template->output() );
}




# ===========================================================================
# View the bookmarks belonging to a user.
# ===========================================================================
sub view_bookmarks
{
    my ($self) = (@_);

    # read in the template file
    my $template = $self->load_layout( "view_bookmarks.inc",
                                       global_vars => 1,
                                       session     => 1
                                     );


    my $form = $self->query();

    #
    #  Get the current logged in user.
    #
    my $session = Singleton::Session->instance();
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  And the user we're viewing.
    #
    my $view_username = $form->param("user") || $username;

    #
    #  If the user is ourself we can delete the bookmarks.
    #
    my $delete   = 0;
    my $is_owner = 0;
    if ( lc($username) eq lc($view_username) )
    {
        $is_owner = 1;
        $delete   = 1;
    }

    #
    # Get the bookmarks
    #
    my $bookmarks = Yawns::Bookmarks->new( username => $view_username );
    my $ref = $bookmarks->get();

    my $article_bookmarks = undef;
    my $poll_bookmarks    = undef;
    my $weblog_bookmarks  = undef;

    if ( defined(@$ref) )
    {
        my @all_bookmarks = @$ref;
        foreach my $row (@all_bookmarks)
        {
            my @row = @$row;

            #
            #  The data
            #
            my $gid   = $row[0];
            my $id    = $row[1];
            my $type  = $row[2];
            my $title = 'Unknown';

            #
            # Fix the title.
            #
            if ( $type eq 'a' )
            {
                my $article = Yawns::Article->new( id => $id );
                my $articles = Yawns::Articles->new( id => $id );
                $title = $article->getTitle();
                my $slug = $articles->makeSlug($title);

                push( @$article_bookmarks,
                      {  gid    => $gid,
                         uid    => $id,
                         delete => $delete,
                         slug   => $slug,
                         title  => $title,
                      } );

            }
            elsif ( $type eq 'w' )
            {
                my $weblog = Yawns::Weblog->new( gid => $id );
                $title = $weblog->getTitle();

                #
                # Build up link to the weblog
                #
                my $owner = $weblog->getOwner();
                my $link  = $weblog->getID();

                push( @$weblog_bookmarks,
                      {  gid    => $gid,
                         delete => $delete,
                         title  => $title,
                         owner  => $owner,
                         link   => $link,
                      } );
            }
            elsif ( $type eq 'p' )
            {
                my $poll = Yawns::Poll->new( id => $id );
                $title = $poll->getTitle();

                push( @$poll_bookmarks,
                      {  gid    => $gid,
                         delete => $delete,
                         id     => $id,
                         title  => $title,
                      } );
            }
        }
    }

    my $has_bookmarks = undef;

    if ( defined $article_bookmarks )
    {
        $template->param( article_bookmarks => $article_bookmarks );
        $has_bookmarks = 1;
    }
    if ( defined $poll_bookmarks )
    {
        $template->param( poll_bookmarks => $poll_bookmarks );
        $has_bookmarks = 1;
    }
    if ( defined $weblog_bookmarks )
    {
        $template->param( weblog_bookmarks => $weblog_bookmarks );
        $has_bookmarks = 1;
    }

    $template->param( has_bookmarks => $has_bookmarks,
                      viewusername  => $view_username,
                      is_owner      => $is_owner
                    );

    if ($has_bookmarks)
    {
        $template->param( title => "Bookmarks for $view_username" );
    }
    else
    {
        $template->param( title => "No bookmarks found" );
    }

    # generate the output
    return ( $template->output() );
}




# ===========================================================================
#  Delete an existing bookmark
# ===========================================================================
sub delete_bookmark
{
    my ($self) = (@_);


    # Validate session token
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  Get access to the form
    #
    my $form = $self->query();

    #
    #  See what we're adding.
    #
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");


    #
    #  Get the id
    #
    my $id = $form->param("id");

    #
    #  Do the addition
    #
    my $bookmarks = Yawns::Bookmarks->new( username => $username );
    $bookmarks->remove( id => $id );

    #
    # Update the cache
    #
    my $c = Yawns::Cache->new();
    $c->flush("Bookmark deleted by user $username");

    return ( $self->redirectURL("/users/$username/bookmarks") );
}



# ===========================================================================
# Follow an advert, recording the click.
# ===========================================================================
sub follow_advert
{
    my ($self) = (@_);

    #
    #  Gain access to the form parameters
    #
    my $form = $self->query();
    my $id   = $form->param('id');

    if ( defined($id) && ( $id =~ /^[0-9]+$/ ) )
    {
        my $adverts = Yawns::Adverts->new();

        #
        #  Record the click
        #
        $adverts->addClick($id);

        #
        #  Redirect to advert target.
        #
        my $details = $adverts->getAdvert($id);
        return ( $self->redirectURL( $details->{ 'link' } ) );

    }
    else
    {
        $id =~ s/<>//g;
        return ("Invalid advert - $id");
    }
}




# ===========================================================================
# Show all active adverts.
# ===========================================================================
sub view_all_adverts
{
    my ($self) = (@_);

    # Get access to the form, session and database handles
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");

    #
    # Is the user an advert administrator?
    #
    my $perms = Yawns::Permissions->new( username => $username );
    my $admin = $perms->check( priv => "advert_admin" );


    # set up the HTML template
    my $template = $self->load_layout("all_adverts.inc");

    #
    #  Fetch all the adverts
    #
    my $ads     = Yawns::Adverts->new();
    my $adverts = $ads->fetchAllActiveAdverts();

    if ($adverts)
    {

        #
        #  Add link to stats for adverts which the current user owns,
        # or for side admins.
        #
        my $data;

        foreach my $ad (@$adverts)
        {
            if ( ( lc( $ad->{ 'owner' } ) eq lc($username) ) ||
                 ($admin) )
            {
                $ad->{ 'stats' } = 1;
            }
            push( @$data, $ad );
        }

        $adverts = $data;

        $template->param( adverts => $adverts );
    }
    else
    {
        $template->param( error => 1 );
    }

    # fill in all the parameters
    $template->param( title => "All Community Adverts" );

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# Show all adverts belonging to the given user
# ===========================================================================
sub adverts_byuser
{
    my ($self) = (@_);


    # Get access to the form, session and database handles
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");

    #
    # Is the user an advert administrator?
    #
    my $perms = Yawns::Permissions->new( username => $username );
    my $admin = $perms->check( priv => "advert_admin" );


    # The user we're working with.
    my $form  = $self->query();
    my $owner = $form->param("user");


    # set up the HTML template
    my $template = $self->load_layout("all_adverts.inc");

    #
    #  Fetch all the adverts
    #
    my $ads     = Yawns::Adverts->new();
    my $adverts = $ads->advertsByUser($owner);

    if ($adverts)
    {

        #
        #  If we're the owner then add a "stats".
        #
        if ( lc($username) eq lc($owner) ||
             ($admin) )
        {
            my $data;

            foreach my $ad (@$adverts)
            {
                $ad->{ 'stats' } = 1;
                push( @$data, $ad );
            }

            $adverts = $data;
        }

        $template->param( by_user => 1, user => $owner );
        $template->param( adverts => $adverts );
    }
    else
    {
        $template->param( by_user => 1, user => $owner );
        $template->param( error => 1 );
    }

    # fill in all the parameters
    $template->param( title => "Adverts by $owner" );

    # generate the output
    return ( $template->output() );
}


# ===========================================================================
# Show all adverts pending or otherwise and allow admin to enable/disable.
# ===========================================================================
sub edit_adverts
{
    my ($self) = (@_);

    # set up the HTML template
    my $template = $self->load_layout( "edit_adverts.inc",
                                       session     => 1,
                                       global_vars => 1
                                     );

    #
    #  Fetch all adverts
    #
    my $ads = Yawns::Adverts->new();

    #
    #  This includes active and not.
    #
    my $adverts = $ads->fetchAllAdverts();

    if ($adverts)
    {
        $template->param( adverts => $adverts );
    }
    else
    {
        $template->param( error => 1 );
    }

    # generate the output
    return ( $template->output() );

}


# ===========================================================================
# Show the performance of the given advert
# ===========================================================================
sub advert_stats
{
    my ($self) = (@_);


    #
    # Advert ID
    #
    my $form = $self->query();
    my $id   = $form->param("id");

    #
    # Get data.
    #
    my $adverts = Yawns::Adverts->new();
    my $data    = $adverts->getAdvert($id);

    #
    # Load the template
    #
    my $template = $self->load_layout("view_campaign.inc");

    my $clickthrough = 0;
    my $status       = "Pending";

    if ( defined( $data->{ 'owner' } ) )
    {
        if ( $data->{ 'shown' } )
        {
            $clickthrough = ( $data->{ 'clicked' } / $data->{ 'shown' } ) * 100;
            $clickthrough = sprintf( "%.2f", $clickthrough );
        }

        if ( $data->{ 'active' } eq 'y' )
        {
            $status = "Active";
            if ( $data->{ 'shown' } >= $data->{ 'display' } )
            {
                $status = "Finished";
            }
        }
    }
    else
    {
        $template->param( error => 1 );
    }

    # set parameters
    $template->param( advert_id         => $id,
                      advert_owner      => $data->{ 'owner' },
                      advert_link       => $data->{ 'link' },
                      advert_link_title => $data->{ 'linktext' },
                      shown             => $data->{ 'shown' },
                      max               => $data->{ 'display' },
                      clicked           => $data->{ 'clicked' },
                      clickthrough      => $clickthrough,
                      status            => $status,
                      title             => "View Campaign $id",
                    );

    # generate the output
    return ( $template->output() );

}


# ===========================================================================
# Delete an advert
# ===========================================================================
sub delete_advert
{

    my ($self) = (@_);

    #
    # validate the session.
    #
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  This requires a login
    #
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "advert_admin" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    #
    #  Remove the advert.
    #
    my $adverts = Yawns::Adverts->new();
    my $form    = $self->query();
    $adverts->deleteAdvert( $form->param('id') );

    #
    #  Show a good message.
    #
    return ( $self->permission_denied( advert_deleted => 1 ) );

}



# ===========================================================================
# Enable an advert.
# ===========================================================================
sub enable_advert
{
    my ($self) = (@_);

    #
    # validate the session.
    #
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  This requires a login
    #
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "advert_admin" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    #
    #  Remove the advert.
    #
    my $adverts = Yawns::Adverts->new();
    my $form    = $self->query();
    $adverts->enableAdvert( $form->param('id') );

    #
    #  Show a good message.
    #
    return ( $self->permission_denied( advert_enabled => 1 ) );
}


# ===========================================================================
# Disable an advert.
# ===========================================================================
sub disable_advert
{

    my ($self) = (@_);

    #
    # validate the session.
    #
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  This requires a login
    #
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "advert_admin" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    #
    #  Remove the advert.
    #
    my $adverts = Yawns::Adverts->new();
    my $form    = $self->query();
    $adverts->disableAdvert( $form->param('id') );

    #
    #  Show a good message.
    #
    return ( $self->permission_denied( advert_disabled => 1 ) );
}

1;
