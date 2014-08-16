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

        # debug
        'debug' => 'debug',

        # Login/Logout
        'login'  => 'application_login',
        'logout' => 'application_logout',

        # Tag operations
        'tag_cloud'  => 'tag_cloud',
        'tag_search' => 'tag_search',

        # Searching
        'article_search' => 'article_search',

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
    my ( $self, $url ) = (@_);

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
                       -status   => "302",
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

    my $session  = $self->param("session");
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

1;
