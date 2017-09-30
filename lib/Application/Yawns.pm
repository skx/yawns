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
use base 'Application::Base';

use CGI::Application::Plugin::HtmlTidy;
use CGI::Application::Plugin::RemoteIP;


#
# Standard module(s)
#
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
use Yawns::About;
use Yawns::Articles;
use Yawns::Comment;
use Yawns::Formatters;
use Yawns::Permissions;
use Yawns::Poll;
use Yawns::Polls;
use Yawns::Submissions;
use Yawns::User;
use Yawns::User;
use Yawns::Weblogs;
use conf::SiteConfig;



#
#  Prerun - Setup MySQL tracing, if we like.
#
sub cgiapp_prerun
{
    my $self = shift;


    #
    #  Cache our output - based on a hash of request which was made
    #
    my $url = "";
    $url .= $ENV{'SCRIPT_URI'};
    $url .= " ";
    $url .= $ENV{'REQUEST_URI'};
    $url .= " ";
    $url .= $ENV{'QUERY_STRING'};

    #
    # If this is cached already then we're good.
    #
    my $hash = md5_hex($url);
    my $file = "/tmp/$hash.cache";

    if ( -e $file )
    {
        $self->{'cached_content'} = $file;
        $self->prerun_mode('serve_cache');
    }


}


#
#  Post-Run - Tidy our generated HTML.
#
sub cgiapp_postrun
{
    my ($self, $contentref) = @_;

    if ( get_conf( 'tidy_html' ) )
    {
        $self->htmltidy_clean($contentref);
    }


    #
    #  Cache our output - based on a hash of request which was made
    #
    my $url = "";
    $url .= $ENV{'SCRIPT_URI'};
    $url .= " ";
    $url .= $ENV{'REQUEST_URI'};
    $url .= " ";
    $url .= $ENV{'QUERY_STRING'};

    #
    # If this is cached already then we're good.
    #
    my $hash = md5_hex($url);
    my $file = "/tmp/$hash.cache";
    return if ( -e $file );

    #
    # Write it out - first line is the request.
    #
    open( my $tmp, ">", $file ) or return;
    print $tmp $url . "\n";
    print $tmp $$contentref;
    close( $tmp );

}


#
#  Flush the sesions
#
sub teardown
{
    my ($self) = shift;
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


sub serve_cache {
    my( $self ) = ( @_ );

    my $file = $self->{'cached_content'};
    my $text = "";
    my $first = "";

    open( my $f, "<", "$file" );
    while( my $line = <$f> )
    {
        if ( length( $first) > 0 ) {
            $text .= $line;
        } else {
            $first = $line;
        }
    }

    $text .= "<!-- $first -->";
    return( $text );
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
        'serve_cache' => 'serve_cache',

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

    $self->header_add( -location => $url,
                       -status   => $status,
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
    my $l = HTML::Template->new( filename          => $page,
                                 cache             => 1,
                                 die_on_bad_params => 0,
                                 %options,
                               );

    #
    #  IPv6 ?
    #
    $l->param( ipv6 => 1 ) if ( $self->is_ipv6() );

    #
    # Setup the meta-data
    #
    $l->param( site_title => get_conf('site_title') );
    $l->param( metadata   => get_conf('metadata') );

    return ($l);
}


# ===========================================================================
# CSRF protection.
# ===========================================================================
sub validateSession
{
    my ($self) = (@_);
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

    my $username = "Anonymous";

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
    return $self->redirectURL("/");
}


#
# Logout the user.
#
sub application_logout
{
    my ($self) = (@_);
    return $self->redirectURL("/");
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
    my $template = $self->load_layout( "archive.inc",
                                       global_vars       => 1,
                                       loop_context_vars => 1
                                     );

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
    my $username = "Anonymous";

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
    my $tags = Yawns::Tags->new();
    my $all  = $tags->getAllTags();

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

    return ( $self->permission_denied( login_required => 1 ) );
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
    my $username = "Anonymous";


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
    my $username = "Anonymous";

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


    my $template = $self->load_layout( "view_article.inc",
                                       loop_context_vars => 1,
                                       global_vars       => 1,
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
    #  Tag addition URL
    #
    $template->param( tag_url => "/ajax/addtag/$article_id/" );

    my $a = Yawns::Articles->new();

    my $slug = $a->makeSlug( $article->{ 'article_title' } || "" );

    # fill in all the parameters you got from the database
    $template->param(
        article_id    => $article_id,
        article_title => $article->{ 'article_title' },

        title          => $article->{ 'article_title' },
        suspended      => $article->{ 'suspended' },
        article_byuser => $article->{ 'article_byuser' },
        article_ondate => $article->{ 'article_ondate' },
        article_attime => $article->{ 'article_attime' },
        article_body   => $article->{ 'article_body' },
        comments       => $article->{ 'comments' },
        logged_in      => $logged_in,
        error          => $error,

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
    my $username  = "Anonymous";
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
             ( $weblog->getScore( gid => $gid ) > 0 ) )

        {
            $template->param( reportable => 1 );
        }
    }
    if ( !$entries || !@$entries )
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
    my $username =  "Anonymous";


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
#  View recently joined usernames
# ===========================================================================
sub recent_users
{
    my ($self) = (@_);
        return ( $self->permission_denied( login_required => 1 ) );
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
    my $username = "Anonymous";

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

    my $realemail = $userdata->{ 'realemail' };
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
    #  Gravitar
    #
    my $gravitar;
    if ($realemail)
    {
        my $size = 32;
        $gravitar = "//www.gravatar.com/avatar.php?gravatar_id=" .
          md5_hex( lc $realemail ) . ";size=" . $size;
    }

    #
    #  Are we viewing the anonymous user?
    #
    my $anon = 1 if ( $viewusername =~ /^anonymous$/i );

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
    # Display weblog link?
    my $weblog        = 0;
    my $weblog_plural = 0;
    if ( defined $weblog_count )
    {
        $weblog = $weblog_count;

        if ( $weblog > 1 ) {$weblog_plural = 1;}
    }

    #
    # open the html template
    #
    my $template = $self->load_layout("view_user.inc");

    my $is_owner = 0;
    if ( lc($username) eq lc($viewusername) )
    {
        $is_owner = 1 unless ($anon);
    }

    my $show_user = 1;
    $show_user = undef if ($error);
    $show_user = undef if ($suspended);

    # set parameters
    $template->param( viewusername    => $viewusername,
                      gravitar        => $gravitar,
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
                      missing_user    => $error,
                      weblogs         => $weblog,
                      weblog_plural   => $weblog_plural,
                      suspended_user  => $suspended,
                      title           => "Viewing $viewusername",
                      show_user       => $show_user,
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

    return ( $self->permission_denied( admin_only => 1 ) );
}



# ===========================================================================
# reject a pending article from the queue.
# ===========================================================================
sub submission_reject
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}


# ===========================================================================
# post a pending article from the queue to the front-page.
# ===========================================================================
sub submission_post
{

    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}


# ===========================================================================
# Edit a pending submission
# ===========================================================================
sub submission_edit
{
    my ($self) = (@_);


    return ( $self->permission_denied( login_required => 1 ) );
}



# ===========================================================================
# view a submission.
# ===========================================================================
sub submission_view
{
    my ($self) = (@_);
        return ( $self->permission_denied( login_required => 1 ) );
}

# ===========================================================================
# List pending articles
# ===========================================================================
sub submission_list
{
    my ($self) = (@_);

        return ( $self->permission_denied( login_required => 1 ) );
}




# ===========================================================================
# User administration.
# ===========================================================================
sub user_admin
{
    my ($self) = (@_);

    return ( $self->permission_denied( admin_only => 1 ) );
}


sub poll_list
{
    my ($self) = (@_);

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

    #
    #  Logged in?
    #
    my $logged_in = 0;


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
    $template->param( tag_url => "/ajax/addtag/poll/$poll_id/" );

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

        my $comments =
          Yawns::Comments->new( poll    => $poll_id,
                                enabled => $enabled );

        $templateC->param( comments => $comments->get("Anonymous"), );

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

    return ( $self->poll_view( 0, 0, 0 ) );
}


# ===========================================================================
# Manage pending submissions; list all polls with links to post/delete
# ===========================================================================
sub pending_polls
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}


# ===========================================================================
#  Post the given poll to the site.
# ===========================================================================
sub poll_post
{
    my ($self) = (@_);

    return ( $self->permission_denied( admin_only => 1 ) );
}


# ===========================================================================
#  Reject/Delete the given poll
# ===========================================================================
sub poll_reject
{
    my ($self) = (@_);
    return ( $self->permission_denied( admin_only => 1 ) );
}




# ===========================================================================
#  Reject/Delete the given poll
# ===========================================================================
sub poll_edit
{
    my ($self) = (@_);

    return ( $self->permission_denied( login_required => 1 ) );
}


#
# Allow a user to enter a poll into the poll submission queue.
#
#
sub submit_poll
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}




# ===========================================================================
# Edit the preferences of a user.
# ===========================================================================
sub edit_prefs
{

    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}



# ===========================================================================
# Edit user permissions
# ===========================================================================
sub edit_permissions
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}



# ===========================================================================
# Send the user a mail allowing them to reset their password.
# ===========================================================================
sub reset_password
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}

# ===========================================================================
# Allow the user to change their password - via the forgotten password
# link - so not in general ..
# ===========================================================================
sub change_password
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}




# ===========================================================================
# Report a comment on a poll, article, or weblog.
# ===========================================================================
sub report_comment
{

    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}




# ===========================================================================
# Report a spammy/abusive/trolly weblog
# ===========================================================================
sub report_weblog
{

    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}




# ===========================================================================
# Add new weblog entry for the given user
# ===========================================================================
sub add_weblog
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}



# ===========================================================================
# Delete a Weblog Entry
# ===========================================================================
sub delete_weblog
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}



# ===========================================================================
# Edit a weblog entry.
# ===========================================================================
sub edit_weblog
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
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
        return ( $self->permission_denied( login_required => 1 ) );
}


# ===========================================================================
# Submit article
# ===========================================================================

sub submit_article
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}



# ===========================================================================
# Edit a comment on a poll, article, or weblog.
# ===========================================================================
sub edit_comment
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}



# ===========================================================================
# Add a comment - This could either be on a poll, an article, or a weblog entry.
#
# ===========================================================================
sub add_comment
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );
}



# ===========================================================================
# create a new user account.
# ===========================================================================
sub new_user
{
    my ($self) = (@_);
    return ( $self->permission_denied( login_required => 1 ) );

}



1;
