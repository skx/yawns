#
# This is a L<CGI::Application> module which powers the site.
#
# The code here is huge because one script contains all the
# run-modes, except:
#
#  * Those related to Ajax requests which are in L<Application::Ajax>
#
#  * Those relating to RSS feeds which are in L<Application::Feeds>
#
# We should further abstract the code but that has not yet been done
# due to lack of time.
#
# I suspect the following would be natural modules:
#
#  * L<Application::Poll> - Poll-related code
#
#  * L<Application::Weblog> - Weblog-related code
#
#  * L<Application::Admin> - Grab-bag of "privileged" operations.
#
# Steve
# --
#


use strict;
use warnings;


#
# Hierarchy.
#
package Application::Yawns;
use base 'CGI::Application';

use CGI::Application::Plugin::RemoteIP;


#
# Standard module(s)
#
use CGI::Session;
use Cache::Memcached;
use Digest::MD5 qw! md5_hex !;
use HTML::Entities qw! encode_entities !;
use HTML::Template;
use JSON;
use LWP::Simple;
use Mail::Verify;
use Text::Diff;


#
# Our code
#
use HTML::AddNoFollow;
use Singleton::Redis;
use Yawns::About;
use Yawns::Comment;
use Yawns::Articles;
use Yawns::Event;
use Yawns::Formatters;
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

    my $session;

    #
    #  Are we using memcached?
    #
    if ( conf::SiteConfig::get_conf("memcached") )
    {

        #
        # The memcached host is the same as the DBI host.
        #
        my $dbserv = conf::SiteConfig::get_conf('dbserv');
        $dbserv .= ":11211";

        #
        # Get the memcached handle.
        #
        my $mem = Cache::Memcached->new(
                                         { servers => [$dbserv],
                                           debug   => 0
                                         } );

        # session setup
        $session =
          new CGI::Session( "driver:memcached", $query, { Memcached => $mem } )
          or
          die($CGI::Session::errstr);
    }
    else
    {
        my $db = Singleton::DBI->instance();
        $session =
          new CGI::Session( "driver:MySQL", undef, { Handle => $db } ) or
          die($CGI::Session::errstr);

    }


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

    if ( $session && $session->param("session_ip") )
    {

        #
        #  Test IP
        #
        my $cur = $self->remote_ip();
        my $old = $session->param("session_ip");

        if ( $cur ne $old )
        {
            my $cur = $self->get_current_runmode();
            if ( $cur !~ /about/i )
            {
                return ( $self->redirectURL("/about/secure") );
            }
        }
    }

    #  Blacklisted?
    my $redis = Singleton::Redis->instance();
    if ( $redis->get( "IP:" . $self->remote_ip() ) )
    {
        my $cur = $self->get_current_runmode();
        if ( $cur !~ /about/i )
        {
            return ( $self->redirectURL("/about/blacklisted") );
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

        # User-actions
        'view_user'        => 'view_user',
        'edit_user'        => 'edit_user',
        'edit_prefs'       => 'edit_prefs',
        'edit_permissions' => 'edit_permissions',
        'new_user'         => 'new_user',

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

        # Polls
        'poll_list'     => 'poll_list',
        'poll_view'     => 'poll_view',
        'poll_vote'     => 'poll_vote',
        'poll_reject'   => 'poll_reject',
        'poll_post'     => 'poll_post',
        'poll_edit'     => 'poll_edit',
        'pending_polls' => 'pending_polls',
        'submit_poll'   => 'submit_poll',

        # Related-Links
        'add_related'    => 'add_related',
        'delete_related' => 'delete_related',

        # Adverts
        'create_advert'    => 'create_advert',
        'follow_advert'    => 'follow_advert',
        'advert_stats'     => 'advert_stats',
        'edit_adverts'     => 'edit_adverts',
        'view_all_adverts' => 'view_all_adverts',
        'enable_advert'    => 'enable_advert',
        'disable_advert'   => 'disable_advert',
        'delete_advert'    => 'delete_advert',
        'adverts_byuser'   => 'adverts_byuser',

        # Submissions
        'submission_reject' => 'submission_reject',
        'submission_edit'   => 'submission_edit',
        'submission_post'   => 'submission_post',
        'submission_view'   => 'submission_view',
        'submission_list'   => 'submission_list',

        # Reporting
        'report_comment' => 'report_comment',
        'report_weblog'  => 'report_weblog',

        # Comment handling
        'add_comment'  => 'add_comment',
        'edit_comment' => 'edit_comment',

        # Weblogs
        'add_weblog'    => 'add_weblog',
        'delete_weblog' => 'delete_weblog',
        'edit_weblog'   => 'edit_weblog',

        # Administrivia
        'recent_users' => 'recent_users',
        'user_admin'   => 'user_admin',

        # Login/Logout
        'login'           => 'application_login',
        'logout'          => 'application_logout',
        'change_password' => 'change_password',
        'reset_password'  => 'reset_password',

        # Tag operations
        'tag_cloud'  => 'tag_cloud',
        'tag_search' => 'tag_search',

        # Article functions.
        'article'         => 'article',
        'article_wrapper' => 'article_wrapper',
        'edit_article'    => 'edit_article',
        'submit_article'  => 'submit_article',

        # Weblogs
        'weblog'        => 'weblog',
        'single_weblog' => 'single_weblog',


        # Searching
        'article_search' => 'article_search',
        'author_search'  => 'author_search',

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

Load a page-template, and the layout.

=end doc

=cut

sub load_layout
{
    my ( $self, $page, %options ) = (@_);

    #
    #  Make sure the snippet exists.
    #
    if ( -e "../templates/pages/$page.out" )
    {
        $page = "../templates/pages/$page.out";
    }
    else
    {
        die "Page not found: $page";
    }

    #
    #  Load our template
    #
    my $l = HTML::Template->new( filename => $page,
                                 cache    => 1,
                                 %options,
                               );

    #
    #  IPv6 ?
    #
    $l->param( ipv6 => 1 ) if ( $self->is_ipv6() );

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
    $l->param( sidebar_text   => $sidebar->getMenu($session) );
    $l->param( login_box_text => $sidebar->getLoginBox($session) );
    $l->param( site_title     => get_conf('site_title') );
    $l->param( metadata       => get_conf('metadata') );

    my $logged_in = 1;

    my $username = $session->param("logged_in") || "Anonymous";
    if ( $username =~ /^anonymous$/i )
    {
        $logged_in = 0;
    }
    $l->param( logged_in => $logged_in );

    return ($l);
}


=begin doc

Send an alert message

=end doc

=cut

sub send_alert
{
    my ( $self, $text ) = (@_);

    #
    #  Abort if we're disabled, or have empty text.
    #
    my $enabled = conf::SiteConfig::get_conf('event_endpoint') || "";
    return unless ( $enabled && length($enabled) );
    return unless ( $text    && length($text) );

    #
    #  Send it.
    #
    my $event = Yawns::Event->new();
    $event->send($text);
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
        $self->send_alert("Form validation failed");
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

    my $date = `date`;
    chomp($date);
    my $host = `hostname`;
    chomp($host);

    my $method = $self->query()->request_method();

    my $text =
      "This $method request was received at $date on $host, from the $username user\n\n";

    #
    #  Environment dump.
    #
    $text .= "\n\n";
    $text .= "Environment\n";
    foreach my $key ( sort keys %ENV )
    {
        $text .= "$key\t\t\t$ENV{$key}\n";
    }

    $text .= "\n\n";
    $text .= "Submissions\n";
    my $form = $self->query();

    foreach my $key ( $form->param() )
    {
        $text .= $key . "\t\t\t" . $form->param($key);
        $text .= "\n";
    }

    # show the remote IP
    $text .= "X-Forwarded-For : " . $self->remote_ip() . "\n";
    $text .= "Is_ipv4 " . $self->is_ipv4() . "\n";
    $text .= "is_ipv6 " . $self->is_ipv6() . "\n";

    $self->header_add( '-type' => 'text/plain' );
    return ($text);
}



#
#  Login
#
sub application_login
{
    my ($self) = (@_);

    my $q       = $self->query();
    my $session = $self->param('session');

    # If already logged in redirect
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
            $template->param( secure => "https://" .
                                $ENV{ 'SERVER_NAME' } . $ENV{ 'REQUEST_URI' },
                              title => "Advanced Login Options"
                            );
        }

        return ( $template->output() );
    }
    else
    {

        #
        # This should be a POST
        #
        if ( $self->query()->request_method() ne "POST" )
        {
            return (
                     $self->permission_denied(
                                          invalid_mode => 1,
                                          title => "Invalid HTTP Request Method"
                     ) );
        }
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
    #  Get the remote IP address.
    #
    my $remote_ip = $self->remote_ip();

    #
    #  If it worked
    #
    if ( ($logged_in) and ( !( lc($logged_in) eq lc('Anonymous') ) ) )
    {
        my $link = $protocol . $ENV{ "SERVER_NAME" } . "/users/$logged_in";

        if( $suspended ) {

            # Record the suspended login.
            $self->send_alert(
                              "Login from suspended user <a href=\"$link\">$logged_in</a> at " .
                              $remote_ip );

            # ban.
            my $redis = Singleton::Redis->instance();
            $redis->set( "IP:" . $remote_ip, "1" );

        }
        else {
            $self->send_alert(
                              "Successful login for <a href=\"$link\">$logged_in</a> from " .
                              $remote_ip );
        }

        #
        #  Setup the session variables.
        #
        $session->param( "logged_in",    $logged_in );
        $session->param( "failed_login", undef );

        #
        #  If the user wanted a secure login bind their cookie to the
        # remote address.
        #
        if ( defined($secure) && ($secure) )
        {
            $session->param( "session_ip", $remote_ip );
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

        $lname = "_unknown_" if ( !defined($lname) );
        $self->send_alert( "Failed login for $lname from " . $remote_ip );

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

    # validate session
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);


    my $remote_ip = $self->remote_ip();
    my $user = $session->param("logged_in") || "Anonymous";
    $self->send_alert( "Successful logout for $user from " . $remote_ip );

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
         ( !$polls )       &&
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

        #
        #  We use L<Lucy::Simple> for the search index.
        #
        #  The search index is built using the script "bin/build-search-index"
        # You will need to add that to cron.
        #
        #  liblucy-perl is present in Debian from Jessie onwards.
        #
        #  For wheezy see:
        #
        #  http://packages.steve.org.uk/lucy/
        #
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

    if ( $action eq "" )
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
    if ( $form->param("submit") eq "Save Changes" )
    {

        # validate session.
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        my $old_page = $form->param('pagename');
        my $new_page = $form->param('page');
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
    my $related = $accessor->getRelated($username);

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
        article_id    => $article_id,
        article_title => $article->{ 'article_title' },

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

        my $ses = $self->param("session");
        $templateC->param( session => md5_hex( $ses->id() ) );


        my $comments = Yawns::Comments->new( article => $article_id );

        #
        #  Only show comments if found.
        #
        my $found = $comments->get($username);
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

            my $sess = $self->param("session");
            $templateC->param( session => md5_hex( $sess->id() ) );

            my $comments =
              Yawns::Comments->new( weblog  => $gid,
                                    enabled => $enabled );

            #
            my $com = $comments->get($username);
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
             length($weblog_owner)  &&
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
    my $count = $form->param('count') || 10;
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
    my $session = $self->param("session");
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




# ===========================================================================
# Add a user-submitted advert.
# ===========================================================================
sub create_advert
{
    my ($self) = (@_);

    #
    # Gain acess to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");


    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    # get new/preview status
    my $submit = '';
    $submit = $form->param('add_advert') if defined $form->param('add_advert');



    # set some variables
    my $new     = 0;
    my $preview = 0;
    my $confirm = 0;
    $new     = 1 if $submit eq 'new';
    $preview = 1 if $submit eq 'Preview';
    $confirm = 1 if $submit eq 'Confirm';

    my $submit_link      = '';
    my $submit_link_text = '';
    my $submit_copy      = '';

    if ($preview)
    {
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        # Details to preview.
        #
        $submit_link      = $form->param('submit_link');
        $submit_link_text = $form->param('submit_link_text');
        $submit_copy      = $form->param('submit_copy');
    }
    elsif ($confirm)
    {
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        # Details we're confirming.
        #
        $submit_link      = $form->param('submit_link');
        $submit_link_text = $form->param('submit_link_text');
        $submit_copy      = $form->param('submit_copy');

        my $advert = Yawns::Adverts->new();

        $advert->addAdvert( link     => $submit_link,
                            linktext => $submit_link_text,
                            text     => $submit_copy,
                            owner    => $username,
                            display  => 5000,
                          );

    }

    # open the html template
    my $template = $self->load_layout( "submit_advert.inc", session => 1 );

    # fill in all the parameters you got from the database
    $template->param( new              => $new,
                      preview          => $preview,
                      confirm          => $confirm,
                      submit_link      => $submit_link,
                      submit_link_text => $submit_link_text,
                      submit_copy      => $submit_copy,
                      title            => "Submit Advert",
                    );

    # generate the output
    return ( $template->output() );
}




# ===========================================================================
# view a users profile page.
# ===========================================================================
sub view_user
{

    my ($self) = (@_);

    #
    # Gain acess to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Permissions checks
    #
    my $edit_user        = 0;
    my $edit_permissions = 0;

    if ( $username !~ /^anonymous$/i )
    {
        my $perms = Yawns::Permissions->new( username => $username );
        $edit_user        = $perms->check( priv => "edit_user" );
        $edit_permissions = $perms->check( priv => "edit_permissions" );
    }


    #
    #  Which user are we to be viewing?
    #
    my $viewusername = $form->param('user');

    #
    #  If no username, then we're viewing ourself.
    #
    if ( ( !defined($viewusername) ) || ( !length($viewusername) ) )
    {
        $viewusername = $username;
    }

    # tidy up URL encoding
    $viewusername =~ s/%20/ /g;

    #
    # Get the user date.
    #
    my $user = Yawns::User->new( username => $viewusername );
    my $userdata = $user->get();

    #
    #  Cope with the user not being found
    #
    my $error = 0;
    if ( !$userdata->{ 'username' } ) {$error = 1;}

    my $fakeemail = $userdata->{ 'fakeemail' };
    my $showemail = 1 if $fakeemail;
    my $realname  = $userdata->{ 'realname' };
    my $showname  = 1 if $realname;
    my $url       = $userdata->{ 'url' };
    my $showurl   = 1 if $url;
    my $bio       = $userdata->{ 'bio' };
    my $showbio   = 1 if $bio;
    my $suspended = $userdata->{ 'suspended' };
    my $articles;
    my $comments;
    my $comment_count;
    my $article_count;

    #
    #  Are we viewing the anonymous user?
    #
    my $anon = 1 if ( $viewusername =~ /^anonymous$/i );


    #
    #  Get scratchpad data to know if we should show it or not.
    #
    my $pad = Yawns::Scratchpad->new( username => $viewusername );
    my $pad_data = '';
    if ( !$pad->isPrivate() )
    {
        $pad_data = $pad->get();
    }

    #
    # Gain access to the user.
    #
    my $a_user = Yawns::User->new( username => $viewusername );
    my $weblog_count = $a_user->getWeblogCount();

    #
    # Get the comments and articles the user has posted.
    #
    # Note: We don't care about anonymous users.
    #
    if ( !$anon )
    {
        $articles      = $a_user->getArticles();
        $article_count = $a_user->getArticleCount();
        $comments      = $a_user->getComments();
        $comment_count = $a_user->getCommentCount();
    }



    #
    # Display scratchpad link?
    #
    my $show_scratchpad = 0;
    if ($pad_data)
    {
        $show_scratchpad = 1;
    }

    #
    # Display weblog link?
    my $weblog        = 0;
    my $weblog_plural = 0;
    if ( defined $weblog_count )
    {
        $weblog = $weblog_count;

        if ( $weblog > 1 ) {$weblog_plural = 1;}
    }

    #
    #  See if the user has any bookmarks
    #
    my $show_bookmarks = 0;
    my $bookmarks = Yawns::Bookmarks->new( username => $viewusername );
    $show_bookmarks = $bookmarks->count();

    #
    # open the html template
    #
    my $template = $self->load_layout("view_user.inc");

    my $is_owner = 0;
    if ( lc($username) eq lc($viewusername) )
    {
        $is_owner = 1 unless ($anon);
    }


    # set parameters
    $template->param( viewusername    => $viewusername,
                      is_owner        => $is_owner,
                      showemail       => $showemail,
                      fakeemail       => $fakeemail,
                      showname        => $showname,
                      realname        => $realname,
                      showurl         => $showurl,
                      url             => $url,
                      showbio         => $showbio,
                      bio             => $bio,
                      anon            => $anon,
                      error           => $error,
                      show_scratchpad => $show_scratchpad,
                      show_bookmarks  => $show_bookmarks,
                      weblogs         => $weblog,
                      weblog_plural   => $weblog_plural,
                      suspended       => $suspended,
                      title           => "Viewing $viewusername"
                    );


    #
    #  Update counts if not anonymous user.
    #
    if ( !$anon )
    {

        #
        #  Show the number and titles of recent articles,
        # comments, etc.
        #
        $template->param( articles      => $articles,
                          comments      => $comments,
                          article_count => $article_count,
                          comment_count => $comment_count,
                        );

        #
        #  Should we show the edit link?  Or the message link?
        #
        my $extra_options = $edit_user + $edit_permissions;
        $template->param( edit_user             => $edit_user,
                          edit_user_permissions => $edit_permissions,
                          extra_options         => $extra_options
                        );

    }



    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# edit user information.
# ===========================================================================
sub edit_user
{
    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in");


    #
    # Per-form variable
    #
    my $edituser = $form->param("edit_user");

    #
    # If no username was specified then use the current logged in user.
    #
    if ( !defined($edituser) || !length($edituser) )
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

        #
        #  Does the current user have permissions to edit
        # a user other than themselves?
        #
        my $perms = Yawns::Permissions->new( username => $username );

        if ( !$perms->check( priv => "edit_user" ) )
        {
            return ( $self->permission_denied( admin_only => 1 ) );
        }
    }

    # check for updates
    my $saved = 0;

    if ( defined $form->param('update') )
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        if ( $form->param('update') eq 'Update' )
        {
            my $user = Yawns::User->new( username => $edituser );
            $user->save( realname  => $form->param('realname'),
                         realemail => $form->param('realemail'),
                         fakemail  => $form->param('fakeemail'),
                         url       => $form->param('url'),
                         sig       => $form->param('sig'),
                         bio       => $form->param('bio') );
            $saved = 1;

        }


    }

    # get the data
    my $user = Yawns::User->new( username => $edituser );
    my $userdata = $user->get();

    my $realemail = $userdata->{ 'realemail' };
    my $fakeemail = $userdata->{ 'fakeemail' };
    my $realname  = $userdata->{ 'realname' };
    my $url       = $userdata->{ 'url' };
    my $bio       = $userdata->{ 'bio' };
    my $sig       = $userdata->{ 'sig' };

    # open the html template
    my $template = $self->load_layout( "edit_user.inc", session => 1 );

    # set parameters
    $template->param( username  => $edituser,
                      realemail => $realemail,
                      fakeemail => $fakeemail,
                      realname  => $realname,
                      url       => $url,
                      bio       => $bio,
                      sig       => $sig,
                      saved     => $saved,
                      title     => "Edit User Information",
                    );

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# reject a pending article from the queue.
# ===========================================================================
sub submission_reject
{
    my ($self) = (@_);


    # validate session
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Anonymous users can't view any submissions.
    #
    if ( $username =~ /^anonymous$/i )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Only an article administrator may do that.
    #
    my $perms = Yawns::Permissions->new( username => $username );

    if ( $perms->check( priv => "article_admin" ) )
    {
        my $id    = $form->param('id');
        my $queue = Yawns::Submissions->new();
        $queue->rejectArticle($id);


        return (
                 $self->permission_denied( submission_rejected => 1,
                                           title => "Submission Rejected"
                                         ) );
    }
    else
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }
}


# ===========================================================================
# post a pending article from the queue to the front-page.
# ===========================================================================
sub submission_post
{

    my ($self) = (@_);


    # validate session
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Anonymous users can't view any submissions.
    #
    if ( $username =~ /^anonymous$/i )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Only an article administrator may do that.
    #
    my $perms = Yawns::Permissions->new( username => $username );

    if ( $perms->check( priv => "article_admin" ) )
    {
        my $id    = $form->param('id');
        my $queue = Yawns::Submissions->new();
        $queue->postArticle($id);

        return (
                 $self->permission_denied( submission_posted => 1,
                                           title => "Submission Posted"
                                         ) );
    }
    else
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }
}


# ===========================================================================
# Edit a pending submission
# ===========================================================================
sub submission_edit
{
    my ($self) = (@_);


    # validate session
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Anonymous users can't edit anything
    #
    if ( $username =~ /^anonymous$/i )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }


    #
    #  If the current user is the article author they may edit it.
    #
    #  The site administrator can edit everything :)
    #
    my $id = $form->param('id');

    if ( defined($id) )
    {
        my $submissions = Yawns::Submissions->new( username => $username );
        my $author = $submissions->getArticleAuthor($id);

        #
        #  If the currently logged in user is the author of the
        # submission, or if we're an article administrator then
        # we can edit.
        #
        if ( lc($author) ne lc($username) )
        {
            my $perms = Yawns::Permissions->new( username => $username );

            if ( !$perms->check( priv => "article_admin" ) )
            {
                return ( $self->permission_denied( admin_only => 1 ) );
            }
        }
    }

    my $stage = $form->param("save_pending");

    #
    #  Submissions object.
    #
    my $submissions = Yawns::Submissions->new();

    #
    #  The template we'll be working with.
    #
    my $template = $self->load_layout( "edit_submission.inc",
                                       global_vars => 1,
                                       session     => 1
                                     );

    #
    #  Are we updating?
    #
    if ( defined($stage) )
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        #  Get the text from the form
        #
        my $title  = $form->param('atitle');
        my $author = $form->param('author');
        my $body   = $form->param('bodytext');
        my $tags   = $form->param('tags');

        #
        #  Run the update.
        #
        $submissions->updateSubmission( id       => $id,
                                        title    => $title,
                                        bodytext => $body,
                                        author   => $author,
                                        tags     => $tags
                                      );

        #
        #  We've updated
        #
        $template->param( saved => 1,
                          id    => $id,
                          title => "Submission Updated"
                        );

    }
    else
    {

        #
        #  Get the data from the submissions queue, and set it into the
        # template
        #
        my %data = $submissions->getSubmission($id);

        #
        #  Get the data.
        #
        my $bodytext     = $data{ 'bodytext' };
        my $title        = $data{ 'title' };
        my $author       = $data{ 'author' };
        my $current_tags = $data{ 'current_tags' };


        #
        #  Make sure entities are encoded.
        #
        $bodytext = HTML::Entities::encode_entities($bodytext);
        $title    = HTML::Entities::encode_entities($title);

        # fill in all the parameters you got from the database
        $template->param( submission_body => $bodytext,
                          atitle          => $title,
                          author          => $author,
                          id              => $id,
                          tags            => $current_tags,
                          title           => "Edit Submission",
                        );

    }

    return ( $template->output() );
}



# ===========================================================================
# view a submission.
# ===========================================================================
sub submission_view
{
    my ($self) = (@_);

    #
    #  This requires a login
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }


    #
    #  Gain access to the objects we use.
    #
    my $form      = $self->query();
    my $perms     = Yawns::Permissions->new( username => $username );
    my $is_author = 0;


    #
    #  If the current user is the article author they may edit it.
    #
    #  The site administrator can edit everything :)
    #
    my $id = $form->param('id');
    if ( defined($id) )
    {
        my $submissions = Yawns::Submissions->new( username => $username );
        my $author = $submissions->getArticleAuthor($id);

        #
        #  If the currently logged in user is the author of the
        # submission, or if we're an article administrator then
        # we can edit.
        #
        if ( lc($author) eq lc($username) )
        {
            $is_author = 1;
        }
        else
        {
            if ( !$perms->check( priv => "article_admin" ) )
            {
                return ( $self->permission_denied( admin_only => 1 ) );
            }
        }
    }


    #
    #  The template we'll be working with.
    #
    my $template = $self->load_layout( "view_submission.inc",
                                       loop_context_vars => 1,
                                       session           => 1
                                     );

    #
    #  Get the data from the submission.
    #
    my $submissions = Yawns::Submissions->new();

    #
    #  Get the data from the submissions queue, and set it into the
    # template
    #
    my %data = $submissions->getSubmission($id);

    #
    #  Does the submission exist?
    #
    my $error = 0;
    $error = 1 if ( !$data{ 'title' } );

    #
    #  Only need to fetch the data if there is no error.
    #
    if ( !$error )
    {

        #
        #  Get the data.
        #
        my $bodytext     = $data{ 'bodytext' };
        my $title        = $data{ 'title' };
        my $author       = $data{ 'author' };
        my $ip           = $data{ 'ip' };
        my $current_tags = $data{ 'current_tags' };
        my $notes        = $data{ 'notes' };



        #
        #  Only the site-admin will see the notes.
        #
        if ( $perms->check( priv => "article_admin" ) )
        {
            $template->param( article_admin => 1 );

        }
        else
        {
            if ($is_author)
            {
                $template->param( is_author => 1 );
            }
        }

        # Get the submission tags.
        my $holder = Yawns::Tags->new();
        my $tags = $holder->getTags( submission => $id );

        if ( defined($tags) )
        {
            $template->param( tags     => $tags,
                              has_tags => 1 );
        }

        # fill in all the parameters you got from the database
        $template->param( submission_body => $bodytext,
                          title           => $title,
                          author          => $author,
                          id              => $id,
                          ip              => $ip,
                        );
    }
    else
    {
        $template->param( error => 1,
                          title => "Error" );
    }

    return ( $template->output() );
}

# ===========================================================================
# List pending articles
# ===========================================================================
sub submission_list
{
    my ($self) = (@_);

    #
    #  This requires a login
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

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
    #  Get the submissions.
    #
    my $queue = Yawns::Submissions->new();
    my $count = $queue->articleCount();
    my $list  = $queue->getArticleOverview();


    #
    #  Load the templaate
    #
    my $template = $self->load_layout( "pending_articles.inc",
                                       global_vars => 1,
                                       session     => 1
                                     );

    #
    #  Add the pending list
    #
    if ( $count < 1 )
    {
        $template->param( empty => 1,
                          title => "No Pending Articles" );
    }
    else
    {
        $template->param( pending_list => $list,
                          title        => "Pending Articles" );
    }

    #
    #  All done
    #
    return ( $template->output() );
}




# ===========================================================================
# User administration.
# ===========================================================================
sub user_admin
{
    my ($self) = (@_);

    # set up the HTML template
    my $template =
      $self->load_layout( "user_administration.inc", session => 1 );

    #
    #  Get the current user.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";


    #
    #  Ensure the user has "user_admin" permissions.
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "user_admin" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    #
    #  Load the permission set we know about.
    #
    my @all_perms = $perms->getKnownAttributes();

    #
    #  Push into a form suitable for our template use.
    #
    my $perms_loop;
    foreach my $key (@all_perms)
    {
        push( @$perms_loop, { perm => $key } );
    }

    #
    #  See what we're doing.
    #
    my $form  = $self->query();
    my $users = Yawns::Users->new();


    my $results;
    my $search = 0;

    if ( defined( $form->param("username") ) )
    {
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        $search = 1;
        $results = $users->search( username => $form->param("username") );
    }
    elsif ( defined( $form->param("email") ) )
    {
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        $search = 1;
        $results = $users->search( email => $form->param("email") );
    }
    elsif ( defined( $form->param("homepage") ) )
    {

        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        $search = 1;
        $results = $users->search( homepage => $form->param("homepage") );
    }
    elsif ( defined( $form->param("permission") ) )
    {
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        $search = 1;
        $results = $users->search( permission => $form->param("permission") );
    }
    if ($results)
    {
        $template->param( "results" => $results );
    }

    #
    #  Always set these.
    #
    $template->param( "search"           => $search );
    $template->param( "count"            => $users->count() );
    $template->param( "permissions_loop" => $perms_loop );
    $template->param( title              => "User Administration" );

    # generate the output
    return ( $template->output() );

}


sub poll_list
{
    my ($self) = (@_);

    #
    # Get access to pointers we need.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    # Get the page from the about section.
    #
    my $polls   = Yawns::Polls->new();
    my $archive = $polls->getPollArchive();

    # set up the HTML template
    my $template = $self->load_layout("prior_polls.inc");

    # fill in the template parameters
    $template->param( poll_archive => $archive,
                      title        => "Prior Poll Archive", );

    # generate the output
    return ( $template->output() );

}



# ===========================================================================
#  Show the poll results and comments.
# ===========================================================================
sub poll_view
{
    my ( $self, $anon_voted, $prev_vote, $new_vote ) = (@_);

    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Logged in?
    #
    my $logged_in = 1;
    $logged_in = 0 if ( $username =~ /anonymous/i );


    my $error = undef;
    my $poll_id = $form->param("id") || 1;

    # meh?
    $anon_voted = 0 if ( !defined($anon_voted) );
    $prev_vote  = 0 if ( !defined($prev_vote) );
    $new_vote   = 0 if ( !defined($new_vote) );

    #
    # Get the poll data.
    #
    my $p = Yawns::Poll->new( id => $poll_id );
    my ( $question, $total, $answers, $author, $date ) = $p->get();

    #
    # Convert the time to a readable value.
    #
    my ( $ondate, $attime ) = Yawns::Date::convert_date_to_site($date);

    if ( ( !defined($date) ) ||
         ( !length($date) ) )
    {
        $date = 0;
    }

    if ( !defined($question) )
    {
        $error = 1;
    }

    $total = 1 if ( !defined($total) );
    $total = 1 if $total < 0;

    # build up answers loop
    my @answers = @$answers;
    my $results = ();
    foreach (@answers)
    {
        my $tmp    = $_;
        my @answer = @$tmp;
        my ( $answer, $votes, $id ) = @answer;

        if ( $prev_vote eq $id )
        {
            $prev_vote = $answer;
        }
        if ( $new_vote eq $id )
        {
            $new_vote = $answer;
        }

        #
        #  Work out voting percentage - but only if there is at
        # least one vote - got to avoid an illegal division by
        # zero!
        #
        my $percent = 0;
        if ( $total > 0 )
        {
            $percent = int( 100 / $total * $votes );
        }

        my $width  = 3 * $percent;
        my $plural = 1;
        $plural = 0 if $votes == 1;

        push( @$results,
              {  answer  => $answer,
                 width   => $width,
                 percent => $percent,
                 votes   => $votes,
                 plural  => $plural,
              } );
    }

    #
    # Do comments exist?
    #
    my $poll = Yawns::Poll->new( id => $poll_id );
    my $comments_exist = $poll->commentCount();

    #
    #  Comment replies are only enabled for the current poll.
    #
    my $polls        = Yawns::Polls->new();
    my $current_poll = $polls->getCurrentPoll();


    my $enabled = 0;
    if ( $current_poll eq $poll_id )
    {
        $enabled = 1;
    }
    else
    {

        #
        #  Poll admin can always add poll tags.
        #
        my $perms = Yawns::Permissions->new( username => $username );
        $enabled = 1 if ( $perms->check( priv => "poll_admin" ) );
    }

    #
    #  Next and previous poll.
    #
    my $next     = '';
    my $next_num = $poll_id + 1;
    $next_num = 0 if ( $next_num > $current_poll );

    my $prev     = '';
    my $prev_num = $poll_id - 1;
    $prev_num = 0 if ( $prev_num < 0 );

    if ($next_num)
    {

        #
        # get the title of the next poll.
        #
        my $poll = Yawns::Poll->new( id => $next_num );
        $next = $poll->getTitle();
    }
    if ( $prev_num >= 0 )
    {

        #
        # Ge the title of the previous poll.
        #
        my $poll = Yawns::Poll->new( id => $prev_num );
        $prev = $poll->getTitle();
    }

    # open the html template
    my $template = $self->load_layout( "poll_results.inc", );

    #
    #  Tag addition URL
    #
    $template->param( tag_url           => "/ajax/addtag/poll/$poll_id/" );
    $template->param( show_poll_archive => 1 );

    if ($error)
    {

        # fill in all the parameters you got from the database
        $template->param( error => $error );
    }
    else
    {

        #
        #  No need to alert if prev_vote == new_vote
        #
        if ( ($prev_vote) &&
             ($new_vote) &&
             ( $prev_vote eq $new_vote ) )
        {
            $prev_vote = undef;
            $new_vote  = undef;
        }

        # fill in all the parameters you got from the database
        $template->param( anon_voted => $anon_voted,
                          prev_vote  => $prev_vote,
                          new_vote   => $new_vote,
                          question   => $question,
                          results    => $results,
                          poll       => $poll_id,
                          comments   => $comments_exist,
                          enabled    => $enabled,
                          next       => $next,
                          next_num   => $next_num,
                          prev       => $prev,
                          prev_num   => $prev_num,
                          byuser     => $author,
                          total      => $total,
                          date       => $date,
                          ondate     => $ondate,
                          logged_in  => $logged_in,
                        );
    }


    # ----- now do the comments section -----
    if ( $comments_exist > 0 )
    {
        my $templateC =
          HTML::Template->new(
                          filename => "../templates/includes/comments.template",
                          global_vars => 1 );

        my $sess = $self->param("session");
        $templateC->param( session => md5_hex( $sess->id() ) );


        my $comments =
          Yawns::Comments->new( poll    => $poll_id,
                                enabled => $enabled );

        $templateC->param( comments => $comments->get($username), );

        # generate the output
        my $comment_text = $templateC->output();
        $template->param( comment_text => $comment_text );
    }

    if ( defined($question) )
    {
        my $title = "Current Poll : " . $question;
        $template->param( title => $title );
    }

    my $tagHolder = Yawns::Tags->new();
    my $tags = $tagHolder->getTags( poll => $poll_id );
    $template->param( tags => $tags ) if ($tags);

    # generate the output
    return ( $template->output() );

}



# ===========================================================================
# Vote in a poll
# ===========================================================================
sub poll_vote
{
    my ($self) = (@_);

    #
    #  Get access to the form.
    #
    my $form = $self->query();

    #
    #  Get our username
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    # The poll the user is voting upon.
    #
    my $poll_id = 0;
    $poll_id = $form->param('poll_id') if $form->param('poll_id');


    #
    # The answer they selected.
    #
    my $poll_answer = undef;
    $poll_answer = $form->param('pollanswer') if $form->param('pollanswer');

    if ( defined $poll_answer )
    {
        my $p = Yawns::Poll->new( id => $poll_id );


        my ( $anon_voted, $prev_vote, $new_vote ) =
          $p->vote( ip_address => $self->remote_ip(),
                    choice     => $poll_answer,
                    username   => $username
                  );

        #
        # Show the result.
        #
        return ( $self->poll_view( $anon_voted, $prev_vote, $new_vote ) );
    }
    else
    {
        return ( $self->poll_view( 0, 0, 0 ) );
    }
}


# ===========================================================================
# Manage pending submissions; list all polls with links to post/delete
# ===========================================================================
sub pending_polls
{
    my ($self) = (@_);

    #
    #  Get the current user.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions.
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "poll_admin" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    # Fetch the pending polls from the database
    my $queue = Yawns::Submissions->new();
    my $subs  = $queue->getPolls();

    # set up the HTML template
    my $template = $self->load_layout( "pending_polls.inc",
                                       global_vars => 1,
                                       session     => 1
                                     );

    # fill in all the parameters
    $template->param( polls => $subs ) if $subs;

    $template->param( title => "Pending Polls" );

    # generate the output
    return ( $template->output() );
}


# ===========================================================================
#  Post the given poll to the site.
# ===========================================================================
sub poll_post
{
    my ($self) = (@_);

    #
    #  Get the current user.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions.
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "poll_admin" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    #
    #  Validate the session.
    #
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);


    #
    # Get the poll ID we are going to post.
    #
    my $form = $self->query();
    my $id   = $form->param("id");

    #
    # Post it.
    #
    my $submisssions = Yawns::Submissions->new();
    $submisssions->postPoll($id);


    #
    #  Redirect to the homepage
    #
    return ( $self->redirectURL("/") );
}


# ===========================================================================
#  Reject/Delete the given poll
# ===========================================================================
sub poll_reject
{
    my ($self) = (@_);

    #
    #  Get the current user.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions.
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "poll_admin" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    #
    #  Validate the session.
    #
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  Get the poll ID we are working with.
    #
    my $form = $self->query();
    my $id   = $form->param("id");

    #
    #  Reject it.
    #
    my $submisssions = Yawns::Submissions->new();
    $submisssions->rejectPoll($id);

    #
    #  Redirect to the homepage
    #
    return ( $self->redirectURL("/submissions/polls") );
}




# ===========================================================================
#  Reject/Delete the given poll
# ===========================================================================
sub poll_edit
{
    my ($self) = (@_);

    #
    #  Get the current user.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    #
    #  Ensure the user has permissions.
    #
    my $perms = Yawns::Permissions->new( username => $username );
    if ( !$perms->check( priv => "poll_admin" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    #
    #  Validate the session.
    #
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  Get the poll ID, and fill out the data.
    #
    my $form   = $self->query();
    my $id     = $form->param("id");
    my $submit = $form->param("submit");

    #
    #  Submission queue object.
    #
    my $submisssions = Yawns::Submissions->new();

    # set up the HTML template
    my $template = $self->load_layout( "edit_poll.inc", session => 1 );

    if ( defined($submit) &&
         $submit eq "Update Poll" )
    {

        my $ans;
        my $count = 1;
        while ( defined( $form->param("answer_$count") ) )
        {
            my $option = $form->param("answer_$count");
            if ( length($option) && ( $option !~ /^[ \t]*$/ ) )
            {
                push( @$ans, $option );
            }
            $count += 1;
        }


        #
        #  Update the submission
        #
        $submisssions->editPendingPoll( $id,
                                        author   => $form->param('author'),
                                        question => $form->param('question'),
                                        answers  => $ans
                                      );

        $template->param( updated => 1,
                          poll_id => $id,
                          title   => "Poll Updated"
                        );

    }
    else
    {
        my ( $author, $question, $answers ) =
          $submisssions->getPendingPoll($id);

        my $ans;
        my $count = 1;
        foreach my $a (@$answers)
        {
            push( @$ans,
                  {  id     => $count,
                     answer => $a
                  } );
            $count += 1;
        }

        # add on a new space.
        push( @$ans,
              {  id     => $count,
                 answer => ""
              } );

        $template->param( author   => $author,
                          question => $question,
                          answers  => $ans,
                          poll_id  => $id,
                          title    => "Edit Poll: $question",
                        );

    }

    return ( $template->output() );
}


#
# Allow a user to enter a poll into the poll submission queue.
#
#
sub submit_poll
{
    my ($self) = (@_);

    #
    # Gain access to the singletons we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";


    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }


    # get new/preview status for article submissions
    my $submit = '';
    $submit = $form->param('submit')
      if defined $form->param('submit');

    my $preview = 0;
    my $blank   = 0;
    my $confirm = 0;
    my $bogus   = 0;
    $preview = 1 if $submit eq 'Preview';
    $confirm = 1 if $submit eq 'Confirm';



    my $question = '';
    my $author   = '';
    my $answer1  = '';
    my $answer2  = '';
    my $answer3  = '';
    my $answer4  = '';
    my $answer5  = '';
    my $answer6  = '';
    my $answer7  = '';
    my $answer8  = '';

    if ($preview)
    {

        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        # get the question + answers.
        $question = $form->param('question') || '';
        $answer1  = $form->param('answer1')  || '';
        $answer2  = $form->param('answer2')  || '';
        $answer3  = $form->param('answer3')  || '';
        $answer4  = $form->param('answer4')  || '';
        $answer5  = $form->param('answer5')  || '';
        $answer6  = $form->param('answer6')  || '';
        $answer7  = $form->param('answer7')  || '';
        $answer8  = $form->param('answer8')  || '';
        $author   = $username;

        # escape entities.
        $question = encode_entities($question);
        $answer1  = encode_entities($answer1);
        $answer2  = encode_entities($answer2);
        $answer3  = encode_entities($answer3);
        $answer4  = encode_entities($answer4);
        $answer5  = encode_entities($answer5);
        $answer6  = encode_entities($answer6);
        $answer7  = encode_entities($answer7);
        $answer8  = encode_entities($answer8);
        $author   = encode_entities($author);

        #
        #  Error?
        #
        if ( !length($question) ||
             !length($answer1) ||
             !length($answer2) )
        {
            $blank = 1;
        }
    }

    if ($confirm)
    {

        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);


        # get the question.
        $question = $form->param('question');
        $question = encode_entities($question);

        # Questions with http:// links in them are bogus.
        $bogus += 1 if ( $question =~ /http:\/\//i );

        # and the username + ip
        $author = $username;
        my $ip = $self->remote_ip();

        my $count = 1;
        my @answers;

        # now find all the potential answers.
        while ( defined( $form->param("answer$count") ) )
        {
            my $ans = $form->param("answer$count");
            $ans = encode_entities($ans);

            # Answers with http:// links in them are bogus.
            $bogus += 1 if ( $ans =~ /http:\/\//i );

            push @answers, $ans;
            $count++;
        }

        #
        #  Add the new poll to the submissions queue if it
        # wasn't bogus.
        #
        if ( $bogus == 0 )
        {
            my $submissions = Yawns::Submissions->new();
            $submissions->addPoll( \@answers,
                                   author   => $author,
                                   ip       => $ip,
                                   question => $question,
                                 );

        }
    }


    # open the html template
    my $template = $self->load_layout( "submit_poll.inc", session => 1 );

    $template->param( preview  => $preview,
                      confirm  => $confirm,
                      question => $question,
                      author   => $author,
                      answer1  => $answer1,
                      answer2  => $answer2,
                      answer3  => $answer3,
                      answer4  => $answer4,
                      answer5  => $answer5,
                      answer6  => $answer6,
                      answer7  => $answer7,
                      answer8  => $answer8,
                      bogus    => $bogus,
                      error    => $blank,
                      title    => "Submit A Poll",
                    );

    return ( $template->output() );
}




# ===========================================================================
# Edit the preferences of a user.
# ===========================================================================
sub edit_prefs
{

    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";


    #
    # Per-form variable
    #
    my $edituser = $form->param("user");

    #
    # If no username was specified then use the current logged in user.
    #
    if ( !defined($edituser) )
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
    #  Does the current user have permissions to edit
    # a user other than themselves?
    #
    my $perms = Yawns::Permissions->new( username => $username );

    #
    #  Editting a different user?
    #
    if ( lc($edituser) ne lc($username) )
    {


        if ( !$perms->check( priv => "edit_user_prefs" ) )
        {
            return ( $self->permission_denied( admin_only => 1 ) );
        }
    }


    #
    #  Get the preference object for working with preferences.
    #
    my $preferences = Yawns::Preferences->new( username => $edituser );

    #
    #  And helper for the notifications
    #
    my $notifications = Yawns::Comment::Notifier->new( username => $edituser );

    #
    #  Flags for displaying result of preference change.
    #
    my $saved             = 0;
    my $password_saved    = 0;
    my $password_mismatch = 0;
    my $password_simple   = 0;


    if ( defined $form->param('update') )
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        if ( $form->param('update') eq 'Update' )
        {
            my $polls   = $form->param('viewpolls')   || 0;
            my $adverts = $form->param('wantadverts') || 0;
            my $blogs   = $form->param('viewblogs')   || 0;


            #
            # Save the preferences.
            #
            my $user = Yawns::User->new( username => $edituser );
            $user->savePreferences( view_polls   => $polls,
                                    view_adverts => $adverts,
                                    view_blogs   => $blogs
                                  );

            #
            #  Find notification options.
            #
            my $article = $form->param("article");
            my $comment = $form->param("comment");
            my $weblog  = $form->param("weblog");

            if ( $perms->check( priv => "article_admin" ) )
            {
                my $submissions = $form->param("submissions");

                # Update them.
                $notifications->save( article     => $article,
                                      comment     => $comment,
                                      weblog      => $weblog,
                                      submissions => $submissions
                                    );

            }
            else
            {

                # Update them.
                $notifications->save( article => $article,
                                      comment => $comment,
                                      weblog  => $weblog
                                    );
            }


            #
            #  Preferences have been changes, now we handle password
            # change.  If required.
            #
            my $pwd1 = $form->param('pw1');
            my $pwd2 = $form->param('pw2');

            #
            #  Only attempt to change password if both fields are non-empty
            #
            if ( ( defined($pwd1) && length($pwd1) ) &&
                 ( defined($pwd2) && length($pwd2) ) )
            {

                #
                # And they both contain the same text.
                #
                if ( $pwd1 ne $pwd2 )
                {
                    $password_mismatch = 1;
                }
                else
                {

                    #
                    #  Password == Username == bad!
                    #
                    if ( lc($pwd1) eq lc($username) )
                    {
                        $password_simple = 1;
                    }
                    else
                    {

                        # set the new password.
                        my $u = Yawns::User->new( username => $edituser );
                        $u->setPassword( $form->param('pw1') );

                        $password_saved = 1;
                    }
                }
            }

            $saved = 1;
        }
    }

    #
    # Get the data.
    #
    my $user        = Yawns::User->new( username => $edituser );
    my $prefsdata   = $user->get();
    my $viewpolls   = $prefsdata->{ 'polls' };
    my $wantadverts = $prefsdata->{ 'viewadverts' };
    my $wantblogs   = $prefsdata->{ 'blogs' };



    #
    #  Get the methods.
    #
    my $article =
      $notifications->getNotificationMethod( $edituser, "article" ) ||
      "none";
    my $comment =
      $notifications->getNotificationMethod( $edituser, "comment" ) ||
      "none";
    my $weblog = $notifications->getNotificationMethod( $edituser, "weblog" ) ||
      "none";
    my $submissions =
      $notifications->getNotificationMethod( $edituser, "submissions" ) ||
      "none";



    # open the html template
    my $template = $self->load_layout( "edit_preferences.inc", session => 1 );

    #
    #  Set notification options.
    #
    $template->param( "article_" . $article => 1 );
    $template->param( "comment_" . $comment => 1 );
    $template->param( "weblog_" . $weblog   => 1 );

    #
    #  NOTE:  perms2 == user being edited, not the user making the change.
    #
    if ( $perms->check( priv => "article_admin" ) )
    {
        $template->param( "submissions_" . $submissions => 1,
                          article_admin                 => 1 );
    }

    # set parameters
    $template->param( username          => $edituser,
                      saved             => $saved,
                      viewpolls         => $viewpolls,
                      password_saved    => $password_saved,
                      password_simple   => $password_simple,
                      password_mismatch => $password_mismatch,
                      wantadverts       => $wantadverts,
                      wantblogs         => $wantblogs,
                      title             => "Edit Preferences",
                    );

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# Edit user permissions
# ===========================================================================
sub edit_permissions
{
    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";
    my $edit     = $form->param("user");

    #
    #  Anonymous users can't edit.
    #
    if ( $username =~ /^anonymous$/i )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }


    #
    #  Gain access to our permissions object.
    #
    my $perms = Yawns::Permissions->new( username => $edit );

    #
    #  Only a permissions-editor can edit permissions.
    #
    if ( !$perms->check( username => $username, priv => "edit_permissions" ) )
    {
        return ( $self->permission_denied( admin_only => 1 ) );
    }

    #
    #  Load the template
    #
    my $template = $self->load_layout( "edit_permissions.inc", session => 1 );


    #
    #  Are we submitting?
    #
    if ( $form->param("change_permissions") )
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        my @all = $perms->getKnownAttributes();

        #
        #  Remove existing parameters.
        #
        $perms->removeAllPermissions($edit);

        #
        #  Now get the ones to set, these are parameters which have
        # name starting with "edit_perm_".
        #
        foreach my $p ( $form->param() )
        {
            if ( $p =~ /edit_perm_(.*)/ )
            {

                #
                #  Defined parameters
                #
                $p = $1;

                #
                #  Is it valid?
                #
                foreach my $q (@all)
                {
                    if ( lc($p) eq lc($q) )
                    {
                        $perms->givePermission( $edit, $p );
                    }
                }
            }
        }

        $template->param( editted => 1,
                          title   => "Permissions Updated",
                          edit    => $edit
                        );

    }
    else
    {

        #
        #  Find all permissions - so we can tick the ones we know
        # about.
        #
        my @all = $perms->getKnownAttributes();

        #
        #  The loop we'll use in the HTML
        #
        my $loop;

        foreach my $key (@all)
        {
            if ( $perms->check( priv => $key ) )
            {
                push( @$loop, { perm => $key, selected => 1 } );
            }
            else
            {
                push( @$loop, { perm => $key, selected => 0 } );
            }
        }

        $template->param( permissions_loop => $loop,
                          edit             => $edit,
                          title            => "Edit Permissions"
                        );
    }

    return ( $template->output() );
}



# ===========================================================================
# Send the user a mail allowing them to reset their password.
# ===========================================================================
sub reset_password
{
    my ($self) = (@_);

    #
    # Deny access if the user is already logged in.
    #
    my $session = $self->param("session");
    my $uname = $session->param("logged_in") || "Anonymous";
    if ( $uname !~ /^anonymous$/i )
    {
        return ( $self->permission_denied( already_logged_in => 1 ) );
    }


    #
    #  Gain access to the objects we use.
    #
    my $form = $self->query();

    my $new_user_name  = '';
    my $new_user_email = '';
    my $submit         = 0;
    my $error          = 0;


    #
    #  If the user is submitting...
    #
    if ( $form->param('submit') eq 'Send' )
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        # get the search details.
        $new_user_name  = $form->param('the_user_name');
        $new_user_email = $form->param('the_user_email');

        #
        # Find the user.
        #
        my $users = Yawns::Users->new();
        my ( $username, $email ) =
          $users->findUser( username => $new_user_name,
                            email    => $new_user_email );

        #
        #  If that worked
        #
        if ( defined($username) &&
             defined($email) &&
             ( lc($username) ne lc("Anonymous") ) )
        {

            #  Get the email address.
            #
            my $user = Yawns::User->new( username => $username );
            my $data = $user->get();
            my $mail = $data->{ 'realemail' };

            # get the hash - but don't leak it.
            my $magic = $user->getPasswordHash();
            $magic = substr( $magic, 0, 16 );

            #
            #  Load up the template for the email
            #
            my $sendmail = conf::SiteConfig::get_conf('sendmail_path');

            #
            # If we don't have sendmail setup then we'll not send out a notice.
            #
            if ( ( !defined($sendmail) ) or
                 ( length($sendmail) < 1 ) )
            {
                return;
            }

            my $template =
              HTML::Template->new(
                      filename => "../templates/mail/reset-password.template" );

            #
            #  Constants.
            #
            my $sender   = get_conf('bounce_email');
            my $sitename = get_conf('sitename');

            $template->param( to         => $mail,
                              from       => $sender,
                              username   => $username,
                              sitename   => $sitename,
                              ip_address => $self->remote_ip(),
                              magic      => $magic,
                            );

            open( SENDMAIL, "|$sendmail -f $sender" ) or
              die "Cannot open $sendmail: $!";
            print( SENDMAIL $template->output() );
            close(SENDMAIL);

            $submit = 1;
        }
        else
        {
            $error = 1;
        }
    }

    # open the html template
    my $template = $self->load_layout( "forgot_password.inc", session => 1 );

    # set the required values
    $template->param( submit => $submit,
                      error  => $error,
                      title  => "Forgotten Password",
                    );

    # generate the output
    return ( $template->output() );

}

# ===========================================================================
# Allow the user to change their password - via the forgotten password
# link - so not in general ..
# ===========================================================================
sub change_password
{
    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form   = $self->query();
    my $user   = $form->param("user");
    my $magic  = $form->param("magic");
    my $pass   = $form->param("newpass");
    my $submit = $form->param("changey");


    # open the html template
    my $template = $self->load_layout( "update_password.inc", session => 0 );

    $template->param( user  => $user,
                      magic => $magic );

    if ($submit)
    {

        #
        #  Get the stored hash of the user.
        #
        my $u = Yawns::User->new( username => $user );
        my $m = $u->getPasswordHash();
        $m = substr( $magic, 0, 16 );

        #
        #  If that matches what we expect then change it.
        #
        if ( $m eq $magic )
        {

            #
            #  Change the password
            #
            $u->setPassword($pass);
            $template->param( submit => 1,
                              title  => "Password Changed" );
        }
    }
    else
    {
        $template->param( title => "Change your password" );
    }



    # generate the output
    return ( $template->output() );

}




# ===========================================================================
#  Add a "related link" to the given article
# ===========================================================================
sub add_related
{

    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    if ( $username !~ /^anonymous$/i )
    {

        #
        #  Test to see if we're an article admin.  That means
        # that we'll see article read counts.
        #
        my $perms = Yawns::Permissions->new( username => $username );
        if ( !$perms->check( priv => "related_admin" ) )
        {
            return ( $self->permission_denied( admin_only => 1 ) );
        }
    }


    #
    #  Article details
    #
    my $article_id    = $form->param("id");
    my $art           = Yawns::Article->new( id => $article_id );
    my $article_title = $art->getTitle();

    #
    # open the html template
    #
    my $template = $self->load_layout( "add_related.inc", session => 1 );

    if ( $form->param("submit") )
    {
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        #  Get details
        #
        my $link  = $form->param("link");
        my $title = $form->param("title");

        #
        #  Add the link
        #
        my $article = Yawns::Article->new( id => $article_id );
        $article->addRelated( $title, $link );


        #
        # So we're done
        $template->param( title   => "Link added",
                          confirm => 1 );


    }
    else
    {
        $template->param( title => "Add related link to $article_title" );
    }


    $template->param( article_id    => $article_id,
                      article_title => $article_title );


    # generate the output
    return ( $template->output() );

}


# ===========================================================================
#  Delete a "related link" from the given article
# ===========================================================================
sub delete_related
{
    my ($self) = (@_);

    # validate session.
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    if ( $username !~ /^anonymous$/i )
    {

        #
        #  Test to see if we're an article admin.  That means
        # that we'll see article read counts.
        #
        my $perms = Yawns::Permissions->new( username => $username );
        if ( !$perms->check( priv => "related_admin" ) )
        {
            return ( $self->permission_denied( admin_only => 1 ) );
        }
    }

    #
    #  Get the parameters.
    #
    my $id      = $form->param('id');
    my $article = $form->param('article_id');

    my $articles = Yawns::Article->new();
    $articles->deleteRelated( $article, $id );

    return ( $self->redirectURL("/articles/$article") );

}



# ===========================================================================
# Report a comment on a poll, article, or weblog.
# ===========================================================================
sub report_comment
{

    my ($self) = (@_);

    #
    #  Get the current user.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }


    #
    #  Validate the session.
    #
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    # Gain access to the form.
    #
    my $form = $self->query();

    #
    # Get the comment details.
    #
    my $article = $form->param("article_id");
    my $poll    = $form->param("poll_id");
    my $weblog  = $form->param("weblog_id");
    my $id      = $form->param("comment_id");

    #
    # Report the comment
    #
    my $comment = Yawns::Comment->new();
    $comment->report( poll     => $poll,
                      article  => $article,
                      weblog   => $weblog,
                      id       => $id,
                      reporter => $username
                    );

    #
    # Show a good result.
    #
    return (
             $self->permission_denied( comment_reported => 1,
                                       title            => "Comment Reported"
                                     ) );
}




# ===========================================================================
# Report a spammy/abusive/trolly weblog
# ===========================================================================
sub report_weblog
{

    my ($self) = (@_);

    #
    #  Get the current user.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }


    #
    #  Validate the session.
    #
    my $ret = $self->validateSession();
    return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

    #
    # Get the entry number.
    #
    my $form = $self->query();
    my $id   = $form->param("id");

    if ( !$session->param( "reported_" . $id ) )
    {

        #
        # Report the comment
        #
        my $entry = Yawns::Weblog->new( gid => $id );
        $entry->report();

        $session->param( "reported_" . $id, 1 );
    }

    #
    # Show a good result.
    #
    return (
             $self->permission_denied( weblog_reported => 1,
                                       title           => "Weblog Reported"
                                     ) );
}




# ===========================================================================
# Add new weblog entry for the given user
# ===========================================================================
sub add_weblog
{
    my ($self) = (@_);

    #
    # Gain acess to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";


    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    # get new/preview status
    my $submit = $form->param('submit') || "";

    # set some variables
    my $new     = 0;
    my $preview = 0;
    my $confirm = 0;
    $new     = 1 if $submit eq 'new';
    $preview = 1 if $submit eq 'Preview';
    $confirm = 1 if $submit eq 'Confirm';

    my $submit_title  = '';
    my $submit_body   = '';
    my $preview_body  = '';
    my $submit_ondate = '';
    my $submit_attime = '';
    my $comments      = $form->param('comments');

    my $blank_title = 0;
    my $blank_body  = 0;

    #
    # Get the titles and body the user submitted.
    #
    $submit_title = $form->param('submit_title') || "";
    $submit_body  = $form->param('submit_body')  || "";


    $submit_title = HTML::Entities::encode_entities($submit_title);

    #
    # Does the user wish to have comments upon their entry?
    #
    my $comments_enabled = 0;
    if ( defined( $form->param('comments') ) &&
         $form->param('comments') =~ /enabled/i )
    {
        $comments_enabled = 1;
    }


    #
    # User is previewing an entry.
    #
    if ($preview)
    {

        # validate session.
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        if ( ( !defined($submit_title) ) ||
             ( length($submit_title) < 1 ) )
        {
            $blank_title = 1;
        }
        if ( ( !defined($submit_body) ) ||
             ( length($submit_body) < 1 ) )
        {
            $blank_body = 1;
        }

        #
        #  Create the correct formatter object.
        #
        my $creator = Yawns::Formatters->new();
        my $formatter = $creator->create( $form->param('type'), $submit_body );


        #
        #  Get the formatted and safe versions.
        #
        $preview_body = $formatter->getPreview();
        $submit_body  = $formatter->getOriginal();

        #
        # Linkize the preview.
        #
        my $linker = HTML::Linkize->new();
        $preview_body = $linker->linkize($preview_body);


        ( $submit_ondate, $submit_attime ) = Yawns::Date::get_str_date();

    }
    elsif ($confirm)
    {

        # validate session.
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);


        if ( ( !defined($submit_title) ) ||
             ( length($submit_title) < 1 ) )
        {
            $blank_title = 1;
        }
        if ( ( !defined($submit_body) ) ||
             ( length($submit_body) < 1 ) )
        {
            $blank_body = 1;
        }
        if ( ( $blank_body == 1 ) ||
             ( $blank_title == 1 ) )
        {
            $preview = 1;
            $confirm = 0;
        }
        else
        {

            #
            #  Create the correct formatter object.
            #
            my $creator = Yawns::Formatters->new();
            my $formatter =
              $creator->create( $form->param('type'), $submit_body );

            #
            #  Get the submitted body.
            #
            $submit_body = $formatter->getPreview();

            #
            # Linkize the preview.
            #
            my $linker = HTML::Linkize->new();
            $submit_body = $linker->linkize($submit_body);


            my $weblog = Yawns::Weblog->new( username => $username );
            $weblog->add( subject          => $submit_title,
                          body             => $submit_body,
                          comments_allowed => $comments_enabled
                        );

        }
    }

    # open the html template
    my $template = $self->load_layout( "add_weblog.inc", session => 1 );

    #
    #  Make sure the format is setup.
    #
    if ( $form->param('type') )
    {
        $template->param( $form->param('type') . "_selected" => 1 );
    }
    else
    {

        #
        #  Choose the users format.
        #
        my $prefs = Yawns::Preferences->new( username => $username );
        my $type = $prefs->getPreference("posting_format") || "text";

        $template->param( $type . "_selected" => 1 );
    }


    # fill in all the parameters you got from the database
    $template->param( sitename         => get_conf('sitename'),
                      new              => $new,
                      preview          => $preview,
                      confirm          => $confirm,
                      username         => $username,
                      submit_title     => $submit_title,
                      submit_body      => $submit_body,
                      preview_body     => $preview_body,
                      submit_ondate    => $submit_ondate,
                      submit_attime    => $submit_attime,
                      comments_enabled => $comments_enabled,
                      blank_title      => $blank_title,
                      blank_body       => $blank_body,
                      title            => "Add New Weblog Entry",
                    );


    #
    #  Show the planet link?
    #
    my $planet_url = conf::SiteConfig::get_conf("planet_url");
    if ( defined($planet_url) )
    {
        $template->param( planet_url  => $planet_url,
                          planet_site => 1,
                          sitename    => conf::SiteConfig::get_conf("sitename")
                        );
    }

    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# Delete a Weblog Entry
# ===========================================================================
sub delete_weblog
{
    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Ensure the user is logged in
    #
    if ( ( !$username ) || ( $username =~ /^anonymous$/i ) )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    my $id = $form->param('id') || 0;

    my $removed = 0;
    my $submit  = $form->param('submit');

    if ( $submit eq 'Yes Really Delete' )
    {

        # validate session.
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        # Find the weblog GID.
        #
        my $weblog = Yawns::Weblog->new();
        my $gid = $weblog->getGID( username => $username, id => $id );

        #
        #  TODO: delete the comments on the entry.
        #
        my $db = Singleton::DBI->instance();
        my $comments =
          $db->prepare("DELETE FROM comments WHERE root=? AND type='w'");
        $comments->execute($gid);
        $comments->finish();

        #
        # Remove the actual entry.
        #
        $weblog->remove( gid      => $gid,
                         username => $username );


        #
        #  All done.
        #
        $removed = 1;
    }
    elsif ( $submit eq 'No Keep It' )
    {
        return ( $self->redirectURL("/users/$username/weblog/$id") );
    }

    # open the html template
    my $template = $self->load_layout( "delete_weblog.inc", session => 1 );

    if ($removed)
    {
        $template->param( title => "Entry Removed" );
    }
    else
    {
        $template->param( title => "Delete Weblog Entry?" );
    }

    # fill in all the parameters you got from the database
    $template->param( removed  => $removed,
                      id       => $id,
                      username => $username,
                    );

    # generate the output
    return ( $template->output() );

}



# ===========================================================================
# Edit a weblog entry.
# ===========================================================================
sub edit_weblog
{
    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    my $id     = $form->param('id');
    my $submit = $form->param('submit');

    my $submit_title = $form->param('submit_title');
    my $submit_tags  = $form->param('submit_tags');


    my $submit_body     = $form->param('submit_body');
    my $submit_comments = $form->param('submit_comments');
    my $saved           = 0;

    #
    # Sanitize.
    #
    $submit_body  = HTML::AddNoFollow::sanitize_string($submit_body);
    $submit_title = HTML::AddNoFollow::sanitize_string($submit_title);

    if ( $submit eq 'Save' )
    {

        # validate session.
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        # Get the weblog.
        #
        my $weblog = Yawns::Weblog->new( username => $username, id => $id );

        #
        # Are we to disable comments?
        #
        my $comments_enabled = 0;
        if ( $submit_comments =~ /enabled/i )
        {
            $comments_enabled = 1;
        }

        #
        #
        #
        $weblog->edit( title            => $submit_title,
                       body             => $submit_body,
                       comments_enabled => $comments_enabled,
                     );


        #
        #  Now handle tags.
        #
        my $tag_helper = Yawns::Tags->new();
        $weblog = Yawns::Weblog->new();
        my $gid = $weblog->getGID( username => $username, id => $id );

        #
        #  Remove existing tags.
        #
        my $tags = $tag_helper->deleteTags( weblog => $gid );

        #
        #  Add any new ones.
        #
        foreach my $tag ( split( /,/, $submit_tags ) )
        {
            next if ( !defined($tag) || !length($tag) );

            # trim leading/trailing whitespace
            $tag =~ s/^\s+|\s+$//g;

            $tag_helper->addTag( weblog => $gid,
                                 tag    => $tag );
        }


        $saved = 1;
    }
    else
    {

        #
        #  Get all tags
        #
        my $tag_helper = Yawns::Tags->new();
        my $weblog     = Yawns::Weblog->new( username => $username );
        my $gid        = $weblog->getGID( username => $username, id => $id );
        my $ent        = $weblog->getSingleWeblogEntry( gid => $gid );
        my @ent        = @$ent;
        my $tags       = $tag_helper->getTags( weblog => $gid );
        my $tag_text   = "";

        foreach my $t (@$tags)
        {
            $tag_text .= "," if ( length($tag_text) );
            $tag_text .= $t->{ 'tag' };
        }

        #
        #  Get the existing blog post.
        #
        $submit_title    = $ent[0]->{ 'title' };
        $submit_body     = $ent[0]->{ 'bodytext' };
        $submit_comments = $ent[0]->{ 'comment_count' };

        #
        #  Ensure entities are escaped.
        #
        $submit_title = HTML::Entities::encode_entities($submit_title);
        $submit_body  = HTML::Entities::encode_entities($submit_body);
        $submit_tags  = HTML::Entities::encode_entities($tag_text);

        #
        #  If submit_comments == -1 then comments are disabled.
        #
        if ( defined($submit_comments) &&
             $submit_comments != -1 )
        {
            $submit_comments = 1;
        }
        else
        {
            $submit_comments = 0;
        }
    }


    # open the html template
    my $template = $self->load_layout( "edit_weblog.inc", session => 1 );


    # fill in all the parameters you got from the database
    $template->param( submit_title    => $submit_title,
                      submit_tags     => $submit_tags,
                      submit_body     => $submit_body,
                      submit_comments => $submit_comments,
                      saved           => $saved,
                      id              => $id,
                      username        => $username,
                      title           => "Edit Weblog",
                    );

    # generate the output
    return ( $template->output() );

}




# ===========================================================================
# View search results:  author search, etc.
# ===========================================================================
sub author_search
{
    my ($self) = (@_);

    my $form = $self->query();
    my $auth = $form->param("author");

    # get required info from database
    my $found;

    my $articles = Yawns::Articles->new();
    $found = $articles->searchByAuthor($auth);

    # set up the HTML template
    my $template =
      $self->load_layout( "search_results.inc", loop_context_vars => 1 );

    # fill in the template parameters
    $template->param( results => $found,
                      title   => "Search Results", );

    # generate the output
    return ( $template->output() );
}




# ===========================================================================
# Edit an existing, published, article
# ===========================================================================
sub edit_article
{
    my ($self) = (@_);

    #
    #  Gain access to the objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    #
    #  Anonymous users can't edit anything.
    #
    if ( $username =~ /^anonymous$/i )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }

    # get id number of article to be edited
    my $article_id = $form->param('id');

    # get new/preview status for article submissions
    my $stage = $form->param('stage') || "new";

    # set some variables
    my $new     = 0;
    my $confirm = 0;
    $new     = 1 if $stage eq 'new';
    $confirm = 1 if $stage eq 'Confirm';

    my $edit_username = '';
    my $edit_title    = '';
    my $edit_body     = '';
    my $edit_ondate   = '';
    my $edit_attime   = '';

    #
    #  Article object.
    #
    my $accessor = Yawns::Article->new( id => $article_id );

    #
    #  Test to see that the edit attempt comes from either the
    # author, or the site-admins.
    #
    my $article_data   = $accessor->get();
    my $article_author = $article_data->{ 'article_byuser' };

    #
    #  If not the author
    #
    if ( lc($article_author) ne lc($username) )
    {

        #
        #  Deny the edit unless we're a site-admin
        #
        my $perms = Yawns::Permissions->new( username => $username );
        if ( !$perms->check( priv => "article_admin" ) )
        {
            return ( $self->permission_denied( admin_only => 1 ) );
        }
    }


    if ($new)
    {

        # get relevant article from database
        my $article = $accessor->get();

        #
        #  Get article data.
        #
        $edit_username = $article->{ 'article_byuser' };
        $edit_ondate   = $article->{ 'article_ondate' };
        $edit_attime   = $article->{ 'article_attime' };
        $edit_title    = $article->{ 'article_title' };
        $edit_body     = $article->{ 'article_body' };

        #
        #  Make sure entities are encoded.
        #
        $edit_title = HTML::Entities::encode_entities($edit_title);
        $edit_body  = HTML::Entities::encode_entities($edit_body);

    }
    elsif ($confirm)
    {
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        $edit_username = $form->param('edit_username');
        $edit_title    = $form->param('edit_title');
        $edit_body     = $form->param('edit_body');


        #
        #  Sanitize unless the user has "raw_html" privileges.
        #
        my $perms = Yawns::Permissions->new( username => $username );
        if ( !$perms->check( priv => "article_admin" ) )
        {
            $edit_body  = HTML::AddNoFollow::sanitize_string($edit_body);
            $edit_title = HTML::AddNoFollow::sanitize_string($edit_title);
        }

        #
        # get the original article from the database, and
        # create a diff of it.
        #
        my $article        = $accessor->get();
        my $original_title = $article->{ 'article_title' };
        my $original_body  = $article->{ 'article_body' };
        my $diff;

        #
        # Only run a diff if something in the article changed.
        #
        if ( $original_body ne $edit_body )
        {
            $diff = diff( \$original_body, \$edit_body );

            if ( length($diff) )
            {
                $diff = "  Here is a context diff of the edit\n" . $diff . "\n";
            }
        }

        #
        # Send mail to both the user who editted the article,
        # and to the site administrator.
        #
        # (Only send to one address if both are identical.)
        #
        my $sendmail = get_conf('sendmail_path');
        if ( ( defined($sendmail) ) &&
             ( length($sendmail) ) )
        {

            #
            # Get the article author.
            #
            my $original_author = $article->{ 'article_byuser' };

            #
            # Find their mail address.
            #
            my $u           = Yawns::User->new( username => $original_author );
            my $d           = $u->get();
            my $author_mail = $d->{ 'realemail' };

            #
            # Get the site administrators mail address.
            #
            my $site_admin = get_conf('site_email');
            my $home_url   = get_conf('home_url');

            #
            # Now send the mail.
            #
            open( SENDMAIL, "|$sendmail -f $site_admin" ) or
              die "Cannot open $sendmail: $!";
            print SENDMAIL<<EOF;
To: $site_admin
From: $site_admin
Subject: [Article-Edit: $edit_title ]
Content-type: text/plain


  Article $article_id has been edited.

  The updated version can be found here:

        $home_url/articles/$article_id

  $diff
Steve
--
http://www.steve.org.uk/
EOF
        }

        #
        #  perform the actual edit.
        #
        $accessor->edit( title  => $edit_title,
                         body   => $edit_body,
                         author => $edit_username
                       );


    }

    # open the html template
    my $template = $self->load_layout( "edit_article.inc", session => 1 );


    $template->param( confirm       => $confirm,
                      article_id    => $article_id,
                      edit_title    => $edit_title,
                      edit_body     => $edit_body,
                      edit_ondate   => $edit_ondate,
                      edit_attime   => $edit_attime,
                      edit_username => $edit_username,
                    );

    if ($confirm)
    {
        $template->param( title => "Article Saved" );
    }
    else
    {
        $template->param( title => "Edit Article" );
    }

    # generate the output
    return ( $template->output() );

}


# ===========================================================================
# Submit article
# ===========================================================================

sub submit_article
{
    my ($self) = (@_);

    #
    # Gain access to objects we use.
    #
    my $form     = $self->query();
    my $session  = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";


    # get new/preview status for article submissions
    my $submit = $form->param('submit') || "new";

    # set some variables
    my $anon    = 0;
    my $new     = 0;
    my $preview = 0;
    my $confirm = 0;
    $anon    = 1 if ( $username =~ /^anonymous$/i );
    $new     = 1 if $submit eq 'new';
    $preview = 1 if $submit eq 'Preview';
    $confirm = 1 if $submit eq 'Confirm';

    my $submit_title  = '';
    my $preview_title = '';
    my $submit_body   = '';
    my $preview_body  = '';

    my $submit_ondate = '';
    my $submit_attime = '';
    my $submission_id = 0;    # ID of the article which has been submitted.


    #
    #  Anonymous users can't post articles
    #
    if ( $username =~ /^anonymous$/i )
    {
        return ( $self->permission_denied( login_required => 1 ) );
    }


    if ($preview)
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        $submit_title = $form->param('submit_title') || " ";
        $submit_body  = $form->param('submit_body')  || " ";

        # HTML Encode the title.
        $submit_title  = HTML::Entities::encode_entities($submit_title);
        $preview_title = $submit_title;

        #
        #  Create the correct formatter object.
        #
        my $creator = Yawns::Formatters->new();
        my $formatter = $creator->create( $form->param('type'), $submit_body );



        #
        #  Get the formatted and safe versions.
        #
        $preview_body = $formatter->getPreview();
        $submit_body  = $formatter->getOriginal();


        #
        # Linkize the preview.
        #
        my $linker = HTML::Linkize->new();
        $preview_body = $linker->linkize($preview_body);


        # get date in human readable format
        ( $submit_ondate, $submit_attime ) = Yawns::Date::get_str_date();

    }
    elsif ($confirm)
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        #  Get the data.
        #
        $submit_title = $form->param('submit_title') || " ";
        $submit_body  = $form->param('submit_body')  || " ";

        # HTML Encode the title.
        $submit_title = HTML::Entities::encode_entities($submit_title);

        #
        #  Create the correct formatter object.
        #
        my $creator = Yawns::Formatters->new();
        my $formatter = $creator->create( $form->param('type'), $submit_body );

        #
        #  Get the submitted body.
        #
        $submit_body = $formatter->getPreview();

        #
        # Linkize the preview.
        #
        my $linker = HTML::Linkize->new();
        $submit_body = $linker->linkize($submit_body);

        my $submissions = Yawns::Submissions->new();
        $submission_id =
          $submissions->addArticle( title    => $submit_title,
                                    bodytext => $submit_body,
                                    ip       => $self->remote_ip(),
                                    author   => $username
                                  );


    }

    # open the html template
    my $template = $self->load_layout( "submit_article.inc", session => 1 );

    # fill in all the parameters you got from the database
    $template->param( anon          => $anon,
                      new           => $new,
                      preview       => $preview,
                      confirm       => $confirm,
                      username      => $username,
                      submit_title  => $submit_title,
                      submit_body   => $submit_body,
                      preview_title => $preview_title,
                      preview_body  => $preview_body,
                      submit_ondate => $submit_ondate,
                      submit_attime => $submit_attime,
                      submission_id => $submission_id,
                      title         => "Submit Article",
                      tag_url => "/ajax/addtag/submission/$submission_id/",
                    );


    #
    #  Make sure the format is setup.
    #
    if ( $form->param('type') )
    {
        $template->param( $form->param('type') . "_selected" => 1 );
    }
    else
    {

        #
        #  Choose the users format.
        #
        my $prefs = Yawns::Preferences->new( username => $username );
        my $type = $prefs->getPreference("posting_format") || "text";

        $template->param( $type . "_selected" => 1 );
    }


    # generate the output
    return ( $template->output() );
}



# ===========================================================================
# Edit a comment on a poll, article, or weblog.
# ===========================================================================
sub edit_comment
{
    my ($self) = (@_);

    #
    #  Comment details we're going to be editing.
    #
    my $form       = $self->query();
    my $poll_id    = $form->param('poll_id');
    my $article_id = $form->param('article_id');
    my $weblog_id  = $form->param('weblog_id');
    my $id         = $form->param('comment_id');

    #
    #  Load our HTML template.
    #
    my $template = $self->load_layout( "edit_comment.inc", session => 1 );


    #
    #  Create the comment
    #
    my $comment = Yawns::Comment->new( article => $article_id,
                                       poll    => $poll_id,
                                       weblog  => $weblog_id,
                                       id      => $id
                                     );


    #
    #  Save the comment if we're supposed to.
    #
    if ( $form->param("submit") )
    {
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        #  Get the body + title from the form if we're editing..
        #
        my $submit_title = $form->param('submit_title');
        my $submit_body  = $form->param('submit_body');

        #
        #  Edit the comment
        #
        $comment->editComment( newtitle => $submit_title,
                               newbody  => $submit_body );

        my $link = undef;
        if ($poll_id)
        {
            $link = "/polls/" . $poll_id . "#comment_" . $id;
        }

        if ($article_id)
        {
            $link = "/articles/" . $article_id . "#comment_" . $id;
        }

        if ($weblog_id)
        {
            my $w            = Yawns::Weblog->new( gid => $weblog_id );
            my $weblog_owner = $w->getOwner();
            my $weblog_id    = $w->getID();
            $link = "/users/$weblog_owner/weblog/$weblog_id";
            $link .= "#comment_" . $id;
        }

        if ( defined($link) ) {$template->param( link => $link );}
        $template->param( saved => 1,
                          title => "Comment Saved" );

    }
    else
    {

        #
        #  Get the current title + body.
        #
        my $commentStuff = $comment->get();
        my $submit_title = $commentStuff->{ 'title' };
        my $submit_body  = $commentStuff->{ 'body' };

        #
        #  Set them in the form
        #
        $template->param( submit_title => $submit_title,
                          submit_body  => $submit_body,
                          title        => "Edit Comment"
                        );
    }


    # fill in all the parameters you got from the database
    $template->param( article_id => $article_id,
                      poll_id    => $poll_id,
                      weblog_id  => $weblog_id,
                      id         => $id,
                    );

    # generate the output
    return ( $template->output() );
}




# ===========================================================================
# Add a comment - This could either be on a poll, an article, or a weblog entry.
#
# ===========================================================================
sub add_comment
{
    my ($self) = (@_);


    #
    #  Gain access to the objects we use.
    #
    my $db        = Singleton::DBI->instance();
    my $form      = $self->query();
    my $session   = $self->param("session");
    my $username  = $session->param("logged_in") || "Anonymous";
    my $anonymous = 0;

    #  Anonymous user?
    $anonymous = 1 if ( $username =~ /^anonymous$/i );

    #
    #  Is the user non-anonymous?
    #
    if ( !$anonymous )
    {

        #
        #  Is the user suspended?
        #
        my $user = Yawns::User->new( username => $username );
        my $userdata = $user->get();

        if ( $userdata->{ 'suspended' } )
        {
            return ( $self->permission_denied( suspended => 1 ) );
        }
    }


    # get new/preview status for comment submissions
    my $comment   = '';
    my $onarticle = undef;
    my $onpoll    = undef;
    my $onweblog  = undef;
    my $oncomment = undef;

    #
    # The comment which is being replied to.
    #
    $comment = $form->param('submit') if defined $form->param('submit');

    #
    #  Article we're commenting on - could be blank for poll comments.
    #
    $onarticle = $form->param('onarticle') if defined $form->param('onarticle');

    #
    #  Poll ID we're commenting on - could be blank for article comments
    #
    $onpoll = $form->param('onpoll') if defined $form->param('onpoll');

    #
    #  Weblog ID we're commenting on.
    #
    $onweblog = $form->param('onweblog') if defined $form->param('onweblog');

    #
    #  Comment we're replying to.
    #
    $oncomment = $form->param('oncomment') if defined $form->param('oncomment');

    # set some variables
    my $new     = 0;
    my $preview = 0;
    my $confirm = 0;
    $new     = 1 if $comment eq 'new';
    $confirm = 1 if $comment eq 'Confirm';
    $preview = 1 if $comment eq 'Preview';


    #
    #  If a user posts a comment we store the time in their
    # session object.
    #
    #  Later comments use this time to test to see if they should
    # slow down.
    #
    my $seconds = $session->param("last_comment_time");
    if ( defined($seconds) &&
         ( ( time() - $seconds ) < 60 ) )
    {

        #
        #  If the comment poster is a privileged user then
        # we'll be allowed to post two comments in sixty seconds,
        # otherwise they'll receive an error.
        #
        my $perms = Yawns::Permissions->new( username => $username );
        if ( !$perms->check( priv => "fast_comments" ) )
        {

            #
            #  Denied.
            #
            return ( $self->permission_denied( too_fast => 1 ) );
        }
    }


    #
    # The data that the user is adding to the page.
    #
    my $submit_title = '';
    my $submit_body  = '';
    my $preview_body = '';


    #
    #  When replying to a comment:
    #
    my $parent_subject = '';
    my $parent_body    = '';
    my $parent_author  = '';
    my $parent_ondate  = '';
    my $parent_ontime  = '';
    my $parent_ip      = '';


    #
    #  Weblog link to manage gid translation
    #
    my $weblog_link = '';

    #
    #  The comment title
    #
    my $title = '';
    if ($onarticle)
    {
        my $art = Yawns::Article->new( id => $onarticle );
        $title = $art->getTitle();
    }
    elsif ($onpoll)
    {
        my $poll = Yawns::Poll->new( id => $onpoll );
        $title = $poll->getTitle();
    }
    elsif ($onweblog)
    {
        my $weblog = Yawns::Weblog->new( gid => $onweblog );
        my $owner  = $weblog->getOwner();
        my $id     = $weblog->getID();
        $title       = $weblog->getTitle();
        $weblog_link = "/users/$owner/weblog/$id";
    }



    #
    #  If we're replying to a comment we want to show the parent
    # comment - so we need to fetch that information.
    #
    if ($oncomment)
    {

        #
        # TODO: Optimize!
        #
        my $comment =
          Yawns::Comment->new( article => $onarticle,
                               poll    => $onpoll,
                               weblog  => $onweblog,
                               id      => $oncomment
                             );
        my $commentStuff = $comment->get();


        $parent_ip      = $commentStuff->{ 'ip' };
        $parent_subject = $commentStuff->{ 'title' };
        $parent_body    = $commentStuff->{ 'body' };
        $parent_author  = $commentStuff->{ 'author' };
        $parent_ontime  = $commentStuff->{ 'time' };
        $parent_ondate  = $commentStuff->{ 'date' };
    }

    #
    #  Get the date and time
    #
    my $submit_ondate = '';
    my $submit_attime = '';

    #
    # Get the date and time
    #
    ( $submit_ondate, $submit_attime ) = Yawns::Date::get_str_date();

    #
    #  And IP address
    #
    my $ip = $self->remote_ip();
    if ( defined($ip) && length($ip) )
    {
        if ( $ip =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/ )
        {
            $ip = $1 . "." . $2 . ".xx.xx";
        }
        if ( $ip =~ /^([^:]+):/ )
        {
            $ip = $1 . ":0xx:0xx:0xxx:0xxx:0xxx:xx";
        }
    }


    #
    # Previewing the comment
    #
    if ($preview)
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        $submit_title = $form->param('submit_title') || "";
        $submit_body  = $form->param('submit_body')  || "";

        # HTML Encode the title.
        $submit_title = HTML::Entities::encode_entities($submit_title);

        #
        #  Create the correct formatter object.
        #
        my $creator = Yawns::Formatters->new();
        my $formatter = $creator->create( $form->param('type'), $submit_body );


        #
        #  Get the formatted and safe versions.
        #
        $preview_body = $formatter->getPreview();
        $submit_body  = $formatter->getOriginal();

        #
        # Linkize the preview.
        #
        my $linker = HTML::Linkize->new();
        $preview_body = $linker->linkize($preview_body);


    }
    elsif ($confirm)
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        #
        # We detect multiple identical comment posting via the
        # session too.
        #
        $submit_body = $form->param('submit_body');
        if ( defined($submit_body) && length($submit_body) )
        {
            my $hash = md5_hex( Encode::encode( "utf8", $submit_body ) );
            my $used = $session->param($hash);


            if ( defined($used) )
            {
                return ( $self->permission_denied( duplicate_comment => 1 ) );
            }
            else
            {
                $session->param( $hash, "used" );
            }
        }


        #
        #  Get the data.
        #
        $submit_title = $form->param('submit_title') || "";
        $submit_body  = $form->param('submit_body')  || "";

        # HTML Encode the title.
        $submit_title = HTML::Entities::encode_entities($submit_title);

        #
        #  "Bad words" testing is *always* used.
        #
        my $stop = get_conf('stop_words');
        if ( defined($stop) && length($stop) )
        {

            #
            #  If the configuration file has a mentioned word
            # then drop the we match.
            #
            foreach my $bad ( split( /,/, $stop ) )
            {
                if ( $submit_body =~ /$bad/i )
                {
                    return (
                             $self->permission_denied( bad_words => 1,
                                                       stop_word => $bad
                                                     ) );
                }
            }
        }

        #
        #  If anonymous we use Steve's RPC server to test comment
        # validity.
        #

        if ( ($anonymous) && ( get_conf("blogspam_test") ) )
        {
            my %params;
            $params{ 'comment' } = $submit_body;
            $params{ 'ip' }      = $self->remote_ip();
            $params{ 'subject' } = $submit_title;

            # Add user-agent
            $params{ 'agent' } = $ENV{ 'HTTP_USER_AGENT' }
              if ( $ENV{ 'HTTP_USER_AGENT' } );


            #
            #  Build up a link to the website we're on.
            #
            my $protocol = "http://";
            if ( defined( $ENV{ 'HTTPS' } ) && ( $ENV{ 'HTTPS' } =~ /on/i ) )
            {
                $protocol = "https://";
            }
            $params{ 'site' } = $protocol . $ENV{ "SERVER_NAME" };

            #
            #  If the module(s) aren't available, or talking to the
            # server fails then we'll allow the comment.
            #
            #  That is clearly the correct thing to do.
            #
            my $drop = 0;
            eval {

                #
                #  Host:port to test against
                #
                my $url = get_conf("blogspam_url");

                #
                #  Special options to use, if any.
                #
                my $opts = get_conf("blogspam_options");
                if ($opts)
                {
                    $params{ 'options' } = $opts;
                }


                #
                #  Serialize the parameters
                #
                my $json = encode_json( \%params );

                #
                #  Make the request.
                #
                my $req = HTTP::Request->new( 'POST', $url );
                $req->header( 'Content-Type' => 'application/json' );
                $req->content($json);

                #
                #  Send the request.
                #
                my $lwp      = LWP::UserAgent->new();
                my $response = $lwp->request($req);


                #
                # The status code and response
                #
                my $code   = $response->code;
                my $result = $response->decoded_content();

                if ( $result =~ /\"SPAM\"/ )
                {
                    $drop = 1;
                }
            };
            if ($drop)
            {
                return ( $self->permission_denied( blogspam => 1 ) );
            }
        }


        #
        #  Create the correct formatter object.
        #
        my $creator = Yawns::Formatters->new();
        my $formatter = $creator->create( $form->param('type'), $submit_body );

        #
        #  Get the submitted body.
        #
        $submit_body = $formatter->getPreview();

        #
        # Linkize the preview.
        #
        my $linker = HTML::Linkize->new();
        $submit_body = $linker->linkize($submit_body);

        #
        #  If we're anonymous
        #
        if ($anonymous)
        {
            if ( $submit_body =~ /http:\/\// )
            {

                #
                #  ANonymous users cannot post links
                #
                return ( $self->permission_denied( anonylink => 1 ) );
            }
        }

        #
        #  Actually add the comment.
        #
        my $comment = Yawns::Comment->new();
        my $num = $comment->add( article   => $onarticle,
                                 poll      => $onpoll,
                                 weblog    => $onweblog,
                                 oncomment => $oncomment,
                                 title     => $submit_title,
                                 username  => $username,
                                 body      => $submit_body,
                                 ip        => $self->remote_ip() );



        #
        #  Now handle the notification sending
        #
        my $notifier =
          Yawns::Comment::Notifier->new( onarticle => $onarticle,
                                         onpoll    => $onpoll,
                                         onweblog  => $onweblog,
                                         oncomment => $oncomment,
                                         ip        => $self->remote_ip(),
                                       );

        #
        #  This will not do anything if the notifications are disabled
        # by the article author, comment poster, etc.
        #
        $notifier->sendNotification( $num, $username );

        #
        # Save the comment time.
        #
        $session->param( "last_comment_time", time() );

        #
        # Save the MD5 hash of the last comment posted.
        #
        $session->param( md5_hex( Encode::encode( "utf8", $submit_body ) ), 1 );



    }
    elsif ($new)
    {
        if ($oncomment)
        {
            my $comment =
              Yawns::Comment->new( article => $onarticle,
                                   poll    => $onpoll,
                                   weblog  => $onweblog,
                                   id      => $oncomment
                                 );
            my $commentStuff = $comment->get();

            $submit_title = $commentStuff->{ 'title' };


            if ( $submit_title =~ /^Re:/ )
            {

                # Comment starts with 'Re:' already.
            }
            else
            {
                $submit_title = 'Re: ' . $submit_title;
            }
        }
        else
        {

            #
            # Get title of article being replied to
            #
            if ($onarticle)
            {
                my $art = Yawns::Article->new( id => $onarticle );
                $submit_title = $art->getTitle();
                $submit_title = 'Re: ' . $submit_title;
            }

            #
            # Get poll question of poll being replied to.
            #
            if ($onpoll)
            {
                my $poll = Yawns::Poll->new( id => $onpoll );
                $submit_title = 'Re: ' . $poll->getTitle();
            }

            #
            # Get weblog title of entry
            #
            if ($onweblog)
            {
                my $weblog = Yawns::Weblog->new( gid => $onweblog );
                $submit_title = 'Re: ' . $weblog->getTitle();
            }
        }

        #
        #  Get the users signature.
        #
        my $u = Yawns::User->new( username => $username );
        my $userdata = $u->get();
        $submit_body = $userdata->{ 'sig' };
    }

    # open the html template
    my $template = $self->load_layout( "submit_comment.inc", session => 1 );

    # fill in all the parameters you got from the database
    $template->param( anon           => $anonymous,
                      new            => $new,
                      confirm        => $confirm,
                      preview        => $preview,
                      username       => $username,
                      onarticle      => $onarticle,
                      oncomment      => $oncomment,
                      onpoll         => $onpoll,
                      onweblog       => $onweblog,
                      weblog_link    => $weblog_link,
                      submit_title   => $submit_title,
                      submit_body    => $submit_body,
                      submit_attime  => $submit_attime,
                      submit_ondate  => $submit_ondate,
                      ip             => $ip,
                      parent_body    => $parent_body,
                      parent_subject => $parent_subject,
                      parent_author  => $parent_author,
                      parent_date    => $parent_ondate,
                      parent_time    => $parent_ontime,
                      parent_ip      => $parent_ip,
                      title          => $title,
                      preview_body   => $preview_body,
                    );

    #
    #  Make sure the format is setup.
    #
    if ( $form->param('type') )
    {
        $template->param( $form->param('type') . "_selected" => 1 );
    }
    else
    {

        #
        #  Choose the users format.
        #
        my $prefs = Yawns::Preferences->new( username => $username );
        my $type = $prefs->getPreference("posting_format") || "text";

        $template->param( $type . "_selected" => 1 );
    }


    # generate the output
    return ( $template->output() );

}




# ===========================================================================
# create a new user account.
# ===========================================================================
sub new_user
{
    my ($self) = (@_);

    # Get access to the form.
    my $form = $self->query();

    #
    #  Get the currently logged in user.
    #
    my $session = $self->param("session");
    my $username = $session->param("logged_in") || "Anonymous";

    # Deny access if the user is already logged in.
    if ( $username !~ /^anonymous$/i )
    {
        return ( $self->permission_denied( already_logged_in => 1 ) );
    }


    my $new_user_name  = '';
    my $new_user_email = '';

    my $new_user_sent  = 0;
    my $already_exists = 0;

    my $blank_email   = 0;
    my $invalid_email = 0;

    my $blank_username   = 0;
    my $invalid_username = 0;
    my $prev_banned      = 0;
    my $prev_email       = 0;
    my $invalid_hash     = 0;
    my $bad_ip           = 0;
    my $mail_error       = "";

    # Remote IP
    my $remote_ip = $self->remote_ip();

    # Do we have recaptcha enabled?
    my $pub = get_conf('rc_pubkey');
    my $sec = get_conf('rc_secret');

    if ( $form->param('submit') eq 'Create User' )
    {

        # validate session
        my $ret = $self->validateSession();
        return ( $self->permission_denied( invalid_session => 1 ) ) if ($ret);

        $new_user_name = $form->param('new_user_name');
        $new_user_name =~ s/&/\+/g;
        $new_user_name =~ s/^\s+|\s+$//g;

        $new_user_email = $form->param('new_user_email');
        $new_user_email =~ s/^\s+|\s+$//g;

        # captcha response, if enabled
        my $cap = $form->param('g-recaptcha-response');


        if ( $new_user_email && ( $new_user_email =~ /^([^+]*)(\+.*)\@(.*)$/ ) )
        {
            $new_user_email = $1 . '@' . $3;
        }


        if ( $new_user_name =~ /^([0-9a-zA-Z_-]+)$/ )
        {
            #
            # Usernames are 1-25 characters long.
            #
            if ( length($new_user_name) > 25 )
            {
                $invalid_username = 1;
            }

            #
            # Make sure we have an email address.
            #
            if ( !length($new_user_email) )
            {
                $blank_email = 1;
            }


            #
            #  See if this user comes from an IP address with a previous suspension.
            #
            my $db = Singleton::DBI->instance();
            my $sql = $db->prepare(
                "SELECT COUNT(username) FROM users WHERE ip=? AND suspended=1");
            $sql->execute($remote_ip);
            $prev_banned = $sql->fetchrow_array();
            $sql->finish();


            $sql = $db->prepare(
                         "SELECT COUNT(username) FROM users WHERE realemail=?");
            $sql->execute($new_user_email);
            $prev_email = $sql->fetchrow_array();
            $sql->finish();

            if ($prev_banned)
            {
                $self->send_alert(
                              "Denied registration for '$new_user_name' from " .
                                  $remote_ip );

                # Blacklist
                my $redis = Singleton::Redis->instance();
                $redis->set( "IP:" . $self->remote_ip(), "1" );

            }
            if ($prev_email)
            {
                $self->send_alert( "Denied registration for in-use email " .
                                   $new_user_email . " " . $remote_ip );
                # Blacklist
                my $redis = Singleton::Redis->instance();
                $redis->set( "IP:" . $self->remote_ip(), "1" );
            }

            #
            #  Test against blogspam.net
            #
            my $content =
              get("http://test.blogspam.net:9999/lookup/$remote_ip");
            if ($content)
            {
                my $j = decode_json($content);
                if ( ($j) && ( $j->{ 'listed' } ) )
                {
                    my $reeson = $j->{ 'listed' };

                    if ( $reeson =~ /false/i )
                    {
                        # nop
                    }
                    else
                    {
                        $bad_ip = 1;

                        $self->send_alert(
                                          "Denied registration - blogspam.net listing of IP $remote_ip <pre>$content</pre>"
                                         );

                        # Blacklist
                        my $redis = Singleton::Redis->instance();
                        $redis->set( "IP:" . $self->remote_ip(), "1" );

                    }
                }
            }

            #
            # Now test to see if the email address is valid
            #
            $invalid_email = Mail::Verify::CheckAddress($new_user_email);

            if ( $invalid_email == 1 )
            {
                $mail_error = "No email address was supplied.";
            }
            elsif ( $invalid_email == 2 )
            {
                $mail_error =
                  "There is a syntaxical error in the email address.";
            }
            elsif ( $invalid_email == 3 )
            {
                $mail_error =
                  "There are no DNS entries for the host in question (no MX records or A records).";
            }
            elsif ( $invalid_email == 4 )
            {
                $mail_error =
                  "There are no live SMTP servers accepting connections for this email address.";
            }

            #
            #  Test if the user passed the recaptcha test.
            #
            my $bad_cap = 0;
            if ( $sec && $pub )
            {
                #
                # Test the recaptcha process.
                #
                my $c_url = "https://www.google.com/recaptcha/api/siteverify";
                $c_url .= "?secret=$sec";
                $c_url .= "&remoteip=$remote_ip";
                $c_url .= "&response=$cap";


                my $content = get($c_url);

                if ( !$content )
                {
                    $bad_cap = 1;

                    $self->send_alert( "Failed to fetch '$c_url'" );

                }
                else
                {
                    # decode JSON
                    my $out = decode_json($content);
                    if ( $out && ( $out->{ 'success' } =~ /true/i ) )
                    {
                        # OK!
                    }
                    else
                    {
                        $bad_cap += 1;

                        $self->send_alert( "Denied access via recaptcha: '$content'" );

                        # Blacklist
                        my $redis = Singleton::Redis->instance();
                        $redis->set( "IP:" . $self->remote_ip(), "1" );
                    }
                }
            }



            #
            # Test to see if the username already exists.
            #
            if (
                 ( $invalid_email +
                   $prev_email +
                   $prev_banned +
                   $invalid_username +
                   $blank_email + $bad_ip + $bad_cap
                 ) < 1
               )
            {
                my $users = Yawns::Users->new();
                my $exists = $users->exists( username => $new_user_name );
                if ($exists)
                {
                    $already_exists = 1;
                }
                else
                {
                    my $password = '';
                    $password =
                      join( '', map {( 'a' .. 'z' )[rand 26]} 0 .. 10 );


                    if ( $new_user_email &&
                         ( $new_user_email =~ /^([^+]*)(\+.*)\@(.*)$/ ) )
                    {
                        $new_user_email = $1 . '@' . $3;
                    }

                    my $user =
                      Yawns::User->new( username  => $new_user_name,
                                        email     => $new_user_email,
                                        password  => $password,
                                        ip        => $remote_ip,
                                        send_mail => 1
                                      );
                    $user->create();

                    $self->send_alert(
                        "New user, <a href=\"http://www.debian-administration.org/users/$new_user_name\">$new_user_name</a>, created from IP $remote_ip."
                    );

                    $new_user_sent = 1;
                }
            }
        }
        else
        {
            if ( length($new_user_name) )
            {
                $invalid_username = 1;
            }
            else
            {
                $blank_username = 1;
            }
        }
    }


    # open the html template
    my $template = $self->load_layout( "new_user.inc", session => 1 );

    if ( $pub && $sec )
    {
        $template->param( recaptcha => $pub );
    }


    # set the required values
    $template->param( new_user_sent    => $new_user_sent,
                      new_user_email   => $new_user_email,
                      already_exists   => $already_exists,
                      invalid_email    => $invalid_email,
                      mail_error       => $mail_error,
                      invalid_username => $invalid_username,
                      blank_email      => $blank_email,
                      blank_username   => $blank_username,
                      prev_banned      => $prev_banned,
                      prev_email       => $prev_email,
                      bad_ip           => $bad_ip,
                      new_user_name    => $new_user_name,
                      new_user_email   => $new_user_email,
                      title            => "Register Account",
                    );

    # generate the output
    return ( $template->output() );

}



1;
