# -*- cperl -*- #

=head1 NAME

Yawns::User - A module for working with a single site user.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::User;
    use strict;

    my $user = Yawns::Users->new( username => 'Steve');

    my $modifier = $user->getModifier();

=for example end


=head1 DESCRIPTION

This module contains code for dealing with a single registered site
user.


=cut


package Yawns::User;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.69 $' =~ m/Revision:\s*(\S+)/;



#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns modules which we use.
#
use conf::SiteConfig;


use Singleton::DBI;

use Yawns::Adverts;
use Yawns::Bookmarks;
use Yawns::Comment::Notifier;
use Yawns::Date;
use Yawns::Permissions;
use Yawns::Preferences;
use Yawns::Scratchpad;
use Yawns::Stats;
use Yawns::Users;
use Yawns::Weblog;
use Yawns::Weblogs;


=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  Allow user supplied values to override our defaults
    #
    foreach my $key ( keys %supplied )
    {
        $self->{ lc $key } = $supplied{ $key };
    }

    bless( $self, $class );
    return $self;

}



=head2 get

  Return a hash containing all the information about this user.

=cut

sub get
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };

    #
    # Otherwise fetch from the database.
    #
    my $db = Singleton::DBI->instance();
    my $sql = $db->prepare(
        "SELECT  username,realemail,fakeemail,realname,url,sig,bio,joined,headlines,polls,viewadverts,blogs,suspended,id FROM users WHERE username=?"
    );

    $sql->execute($username) or die $db->errstr();
    my @thisuser = $sql->fetchrow_array();

    $sql->finish();

    #
    # convert date and time to more readable format
    #
    my @joined = Yawns::Date::convert_date_to_site( $thisuser[9] );

    my %the_user = ( username    => $thisuser[0],
                     realemail   => $thisuser[1],
                     fakeemail   => $thisuser[2],
                     realname    => $thisuser[3],
                     url         => $thisuser[4],
                     sig         => $thisuser[5],
                     bio         => $thisuser[6],
                     joined      => $joined[7],
                     headlines   => $thisuser[8],
                     polls       => $thisuser[9],
                     viewadverts => $thisuser[10],
                     blogs       => $thisuser[11],
                     suspended   => $thisuser[12],
                     id          => $thisuser[13],
                   );


    #
    #  Fix URLs to include 'http://' if they start with 'www'.
    #
    #  Grr.
    #
    if ( ( defined( $the_user{ 'url' } ) ) &&
         ( length $the_user{ 'url' } ) &&
         ( $the_user{ 'url' } =~ /^www/ ) )
    {
        $the_user{ 'url' } = 'http://' . $the_user{ 'url' };
    }

    return ( \%the_user );
}



=head2 getPasswordHash

  Get the password hash for the given user - only used for the
 password forgotten link.

=cut

sub getPasswordHash
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };

    #
    #  Fetch the hash
    #
    my $db    = Singleton::DBI->instance();
    my $query = $db->prepare('SELECT password FROM users WHERE username=?');
    $query->execute($username);
    my $hash = $query->fetchrow_array();

    #
    #  Return
    #
    return ($hash);
}


=head2 getModifier

  Return the modifier text displayed next to the user's name in any
 comments they leave.

=cut

sub getModifier
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };

    #
    #  Optimization.
    #
    if ( ( $username =~ /^anonymous$/i ) ||
         ( !$class->exists() ) )
    {
        return ("");
    }


    my $magic = "";


    #
    # Does the user have any scratchpad content?
    #
    my $scratchpad = Yawns::Scratchpad->new( username => $username );

    #
    #  Only fetch the text if it is not-private.
    #
    my $scratchpad_text;
    if ( !$scratchpad->isPrivate() )
    {
        $scratchpad_text = $scratchpad->get();
    }

    if ( !defined($scratchpad_text) )
    {
        $scratchpad_text = "";
    }

    $magic = "";


    #
    # If so link it in.
    #
    if ( length($scratchpad_text) )
    {
        $magic = "[ " if ( !length($magic) );
        $magic .= "<a href=\"/users/";
        $magic .= $username;
        $magic .= "/scratchpad\">View ";
        $magic .= $username;
        $magic .= "'s Scratchpad</a> | ";
    }


    #
    # Weblog?
    #
    my $weblog_count = $class->getWeblogCount() || 0;

    if ($weblog_count)
    {
        $magic = "[ " if ( !length($magic) );
        $magic .= "<a href=\"/users/";
        $magic .= $username;
        $magic .= "/weblog\">View Weblogs</a> | ";
    }


    if ( length($magic) > 4 )
    {

        # Remove trailing "|" if present.
        $magic =~ s/\|[ \t]*$//g;

        # Terminator
        $magic .= ']';
    }



    return ($magic);

}




=head2 getWeblogCount

  Return the number of weblog items the user has posted.

=cut

sub getWeblogCount
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };

    die "No username " if ( !defined($username) );

    my $count = "";

    #
    # Otherwise fetch from the database
    #
    my $db    = Singleton::DBI->instance();
    my $query = $db->prepare('SELECT COUNT(id) FROM weblogs WHERE username=?');
    $query->execute($username);
    $count = $query->fetchrow_array();

    return ($count);
}



=head2 getComments

  Return all the comments this user has posted.

=cut

sub getComments
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };

    die "No username " if ( !defined($username) );


    my $details;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Fetch the comments
    #
    my $querystr =
      "SELECT id,root,type,title,ondate FROM comments WHERE score>0 AND author=? ORDER BY ondate DESC LIMIT 10";
    my $sql = $db->prepare($querystr);
    $sql->execute($username);

    #
    # Bind the columns
    #
    my ( $id, $root, $type, $title, $date );
    $sql->bind_columns( undef, \$id, \$root, \$type, \$title, \$date );

    my $resultsloop = [];
    while ( $sql->fetch() )
    {

        #
        #  Prettyfy results.
        #
        my ($str_date) = Yawns::Date::convert_date_to_site($date);
        $title = 'No subject' unless length($title);

        #
        #  Article comment
        #
        if ( $type eq 'a' )
        {
            push( @$resultsloop,
                  {  id      => $id,
                     article => $root,
                     title   => $title,
                     ondate  => $str_date
                  } );
        }

        #
        #  Poll comment
        #
        if ( $type eq 'p' )
        {
            push( @$resultsloop,
                  {  id      => $id,
                     poll    => $root,
                     is_poll => 1,
                     title   => $title,
                     ondate  => $str_date
                  } );
        }

        #
        #  Weblog comments
        #
        if ( $type eq 'w' )
        {

            #
            # Build up the weblog link
            #
            my $weblog = Yawns::Weblog->new( gid => $root );
            my $weblog_link = $weblog->getLink();

            push(
                @$resultsloop,
                {  id          => $id,
                   weblog_link => $weblog_link,
                   ondate      => $str_date,
                   title       => $title,

                } );

        }
    }
    $sql->finish();



    return ($resultsloop);

}



=head2 getArticles

  Return all the articles this user has posted.

=cut

sub getArticles
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };

    die "No username " if ( !defined($username) );


    my $details;

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Fetch the data
    #
    my $querystr =
      "SELECT id,title,ondate FROM articles WHERE author=? ORDER BY id DESC LIMIT 10";
    my $sql = $db->prepare($querystr);
    $sql->execute($username);

    #
    # Bind the columns.
    #
    my ( $id, $title, $date );
    $sql->bind_columns( undef, \$id, \$title, \$date );

    my $articles = Yawns::Articles->new();

    my $resultsloop = [];
    while ( $sql->fetch() )
    {
        my ($str_date) = Yawns::Date::convert_date_to_site($date);

        my $slug = $articles->makeSlug($title);

        push( @$resultsloop,
              {  slug   => $slug,
                 title  => $title,
                 id     => $id,
                 ondate => $str_date
              } );
    }
    $sql->finish();

    return ($resultsloop);
}



=head2 getCommentCount

  Return the number of comments this user has posted.

=cut

sub getCommentCount
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };

    die "No username " if ( !defined($username) );


    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    # Get the count from the database
    my $query =
      $db->prepare('SELECT COUNT(*) FROM comments WHERE score>0 AND author=?');
    $query->execute($username);
    my $count = $query->fetchrow_array();

    return ($count);
}



=head2 getArticleCount

  Return the number of articles this user has posted.

=cut

sub getArticleCount
{
    my ($class) = (@_);

    #
    #  The username we're working with.
    #

    my $username = $class->{ 'username' };
    die "No username " if ( !defined($username) );


    #
    # Get database handle
    #
    my $db = Singleton::DBI->instance();

    #
    # Fetch data
    my $query = $db->prepare('SELECT COUNT(*) FROM articles WHERE author=?');
    $query->execute($username);
    my $count = $query->fetchrow_array();

    return ($count);

}



=head2 create

  Create the given user with the given email address.

=cut

sub create
{
    my ($class) = (@_);

    #
    #  The username and email address we should work with.
    #
    my $username  = $class->{ 'username' };
    my $email     = $class->{ 'email' };
    my $password  = $class->{ 'password' };
    my $ip        = $class->{ 'ip' };
    my $suspended = 0;

    $suspended = 1 if ( $email && ( $email =~ /goood-mail.org/i ) );

    if ( ( !defined($username) ) ||
         ( !length($username) ) ||
         ( !defined($email) || ( !length($email) ) ) ||
         ( !defined($password) || ( !length($password) ) ) )
    {
        die
          "All of the options 'email', 'username', and 'password' must be specified";
    }

    #
    #  Create new notification options.
    #
    my $notifications = Yawns::Comment::Notifier->new( username => $username );
    $notifications->setupNewUser();

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Insert the user.
    #
    my $sql = $db->prepare(
        'INSERT INTO users (username,password,realemail,joined,viewadverts,headlines,suspended,ip) VALUES( ?, MD5(?), ?, NOW(), 1, 1,?,?)'
    );
    $sql->execute( $username, $password, $email, $suspended, $ip ) or
      die " Failed to create user - " . $db->errstr();
    $sql->finish();

    #
    #  Send the new user an email if we're supposed to.
    #
    if ( ( defined( $class->{ 'send_mail' } ) && $class->{ 'send_mail' } ) )
    {

        #
        #  Send the mail.
        #
        $class->sendMail();
    }

}



=head2 exists

  Does the user exist?

=cut

sub exists
{
    my ($class) = (@_);

    #
    #  Test we have a username.
    #
    die "No username to test" unless ( defined( $class->{ 'username' } ) );

    #
    #  Test the existance.
    #
    my $users = Yawns::Users->new();
    my $result = $users->exists( username => $class->{ 'username' } );

    return ($result);
}


=head2 sendMail

  Send an email to a freshly created user informing them of their
 new account details.

=cut

sub sendMail
{
    my ($class) = (@_);

    #
    #  The username and email address we should work with.
    #
    my $username = $class->{ 'username' };
    my $email    = $class->{ 'email' };
    my $password = $class->{ 'password' };

    die "No username" if !defined($username);
    die "No email"    if !defined($email);
    die "No password" if !defined($password);

    my $sitename     = get_conf('sitename');
    my $bounce_email = get_conf('bounce_email');
    my $sendmail     = get_conf('sendmail_path');

    if ( ( !defined($sendmail) ) or
         ( length($sendmail) < 1 ) )
    {
        return;
    }

    my $template =
      HTML::Template->new(
                         filename => "../templates/mail/new-account.template" );

    #
    # Setup the parameters.
    #
    $template->param( name       => $username,
                      password   => $password,
                      address    => $email,
                      sitename   => $sitename,
                      site_email => $bounce_email
                    );


    open( SENDMAIL, "|$sendmail -f $bounce_email" ) or
      die "Cannot open $sendmail: $!";
    print( SENDMAIL $template->output() );
    close(SENDMAIL);

}



=head2 setPassword

  Set the password for the current user.

=cut

sub setPassword
{
    my ( $class, $password ) = (@_);

    #
    #  The username we're working with.
    #
    my $username = $class->{ 'username' };

    die "No username " if ( !defined($username) );

    #
    # Set the password.
    #
    my $db  = Singleton::DBI->instance();
    my $sql = $db->prepare('UPDATE users SET password=MD5(?) WHERE username=?');
    $sql->execute( $password, $username );
    $sql->finish();

    $class->{ 'password' } = $password;
}



=head2 delete

  Delete the given user.

=cut

sub delete
{
    my ($class) = (@_);


    #
    #  The username we should delete.
    #
    my $username = $class->{ 'username' };


    #
    #  Flush the preferences - do this before we remove the user
    # so the userid is available.
    #
    my $preferences = Yawns::Preferences->new( username => $username );
    $preferences->deleteByUser();


    #
    # Get the database handle, and get ready to delete.
    #
    my $db  = Singleton::DBI->instance();
    my $sql = $db->prepare('DELETE FROM users WHERE username=?');

    #
    # Perform the deletion.
    #
    $sql->execute($username);
    $sql->finish();


    #
    #  Flush the scratchpad.
    #
    my $scratchpad = Yawns::Scratchpad->new( username => $username );
    $scratchpad->set( "", "public" );
    $scratchpad->invalidateCache();

    #
    #  Flush the notification options
    #
    my $notifier = Yawns::Comment::Notifier->new( username => $username );
    $notifier->deleteNotifications();

    #
    #
    #  Flush any administrative permissions
    #
    my $perms = Yawns::Permissions->new();
    $perms->removeAllPermissions($username);

    #
    #  Flush the hall of fame count, and the count of users.
    #
    my $stats = Yawns::Stats->new();
    $stats->invalidateCache();

    my $users = Yawns::Users->new();
    $users->invalidateCache();

    #
    # Delete all weblogs.
    #
    my $weblogs = Yawns::Weblogs->new( username => $username );
    $weblogs->deleteByUser();


    #
    # Delete all adverts
    #
    my $adverts = Yawns::Adverts->new( username => $username );
    $adverts->deleteByUser();

    #
    # Delete all bookmarks
    #
    my $bookmarks = Yawns::Bookmarks->new( username => $username );
    $bookmarks->deleteByUser();

}



=head2 suspend

  Suspend the given user.

    suspendUser( reason   => 'I dont like him' );

=cut

sub suspend
{
    my ( $class, %params ) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();


    my $username = $class->{ 'username' };
    my $details  = $params{ 'reason' };

    if ( ( !defined($username) ) ||
         ( !length($username) ) ||
         ( !defined($details) ) ||
         ( !length($details) ) )
    {
        die "Both 'username' and 'details' must be given";
    }

    my $querystr = "update users SET suspended=?,bio=? WHERE username=?";
    my $query    = $db->prepare($querystr);

    $query->execute( 1, $details, $username );
    $query->finish();

}



=head2 save

  Update the given user's details.

    save( realname => "Steve Kemp",
          realemail => 'foo@bar.com',
          fakeemail => 'fooo /at/ bar.com',
          url       => 'http://www.steve.org.uk',
          sig       => 'My Sig',
          bio       => 'I wrote this' );

=cut

sub save
{
    my ( $class, %params ) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  The data we will save.
    #
    my $username  = $class->{ 'username' };
    my $realname  = $params{ 'realname' };
    my $realemail = $params{ 'realemail' };
    my $fakemail  = $params{ 'fakemail' };
    my $url       = $params{ 'url' };
    my $sig       = $params{ 'sig' };
    my $bio       = $params{ 'bio' };


    my $sql = $db->prepare( 'UPDATE users SET realname=?, realemail=?, ' .
                   'fakeemail=?, url=?, sig=?, bio=? ' . 'WHERE username = ?' );
    $sql->execute( $realname, $realemail, $fakemail, $url, $sig, $bio,
                   $username );
    $sql->finish();

}



=head2 savePreferences

  Update the given user preferences.

    savePreferences(
          view_headlines     => 1,
          view_polls         => 1,
          view_adverts       => 1,
          view_blogs         => 1,
          css_url            => '' );


=cut

sub savePreferences
{
    my ( $class, %params ) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    #  The data we will save.
    #
    my $username = $class->{ 'username' };

    die "No username " if ( !defined($username) );

    #
    # View previous headlines in the sidebar?
    #
    my $view_headlines = $params{ 'view_headlines' };
    if ( defined($view_headlines) )
    {
        my $sql = $db->prepare("UPDATE users SET headlines=? WHERE username=?");
        $sql->execute( $view_headlines, $username ) or die $db->errstr();
        $sql->finish();

    }

    #
    # View polls in the sidebar?
    #
    my $view_polls = $params{ 'view_polls' };
    if ( defined($view_polls) )
    {
        my $sql = $db->prepare("UPDATE users SET polls=? WHERE username=?");
        $sql->execute( $view_polls, $username ) or die $db->errstr();
        $sql->finish();
    }


    #
    # View weblogs in the sidebar?
    #
    my $view_blogs = $params{ 'view_blogs' };
    if ( defined($view_blogs) )
    {
        my $sql = $db->prepare("UPDATE users SET blogs=? WHERE username=?");
        $sql->execute( $view_blogs, $username ) or die $db->errstr();
        $sql->finish();

    }


    #
    # View adverts in the articles?
    #
    my $view_adverts = $params{ 'view_adverts' };
    if ( defined($view_adverts) )
    {
        my $sql =
          $db->prepare("UPDATE users SET viewadverts=? WHERE username=?");
        $sql->execute( $view_adverts, $username ) or die $db->errstr();
        $sql->finish();

    }

}



=head2 login

  Attempt to login the given user.

  Return ( $success, $suspended ) where:

    success   = 1 if the login was ok, 0 otherwise.
    suspended = 1 if the user has been suspended.

=cut

sub login
{
    my ( $class, %params ) = (@_);

    #
    #  The data we will use to do the login test.
    #
    my $username = $params{ 'username' } || $class->{ 'username' } || "";
    my $password = $params{ 'password' } || $class->{ 'password' } || "";

    #
    # Can't happen.
    #
    die "No username" if ( !defined($username) );
    die "No password" if ( !defined($password) );


    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    # fetch all the required data
    my $sql = $db->prepare(
        "SELECT username,suspended FROM users WHERE username=? AND password=MD5(?)"
    );
    $sql->execute( $username, $password );

    my @thisuser = $sql->fetchrow_array();
    $sql->finish();

    # If there's no matching user we've got a failed login.
    unless (@thisuser) {return 0;}

    # Otherwise return username + suspension flag.
    return ( $thisuser[0], $thisuser[1] );
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ($class) = (@_);
}



1;



=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/



=head1 LICENSE

Copyright (c) 2005,2006 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
