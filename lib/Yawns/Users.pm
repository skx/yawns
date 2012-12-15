# -*- cperl -*- #

=head1 NAME

Yawns::Users - A module for working with site users.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Users;
    use strict;

    my $search = Yawns::Users->new();

    my $results = $search->search( email => 'foo@bar.com' );

=for example end


=head1 DESCRIPTION

This module contains code for dealing with the registered users of a
Yawns powered site.

=cut


package Yawns::Users;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.23 $' =~ m/Revision:\s*(\S+)/;



#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns modules which we use.
#
use Singleton::DBI;
use Singleton::Memcache;
use Yawns::User;


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
    return ($self);
}


=head2 search

  Search for users registered upon the site, and return the results.

=cut

sub search
{
    my ( $class, %search ) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    #
    # Query we will execute, and the search term submitted.
    #
    my $querystr = 'SELECT username,url,realemail FROM users';
    my $term     = '';

    if ( $search{ 'email' } )
    {
        $term = $db->quote( '%' . $search{ 'email' } . '%' );
        $querystr .= " WHERE realemail LIKE $term";

    }
    elsif ( $search{ 'username' } )
    {
        $term = $db->quote( '%' . $search{ 'username' } . '%' );
        $querystr .= " WHERE username LIKE $term";
    }
    elsif ( $search{ 'homepage' } )
    {
        $term = $db->quote( '%' . $search{ 'homepage' } . '%' );
        $querystr .= " WHERE url LIKE $term";
    }
    elsif ( $search{ 'permission' } )
    {

        #
        #  HACK.
        #
        $querystr =
          "SELECT a.username,a.url,a.realemail FROM users AS a INNER JOIN permissions AS b WHERE a.username = b.username AND b.permission=";
        $term = $db->quote( $search{ 'permission' } );
        $querystr .= $term;

    }
    else
    {
        die "No recognised search parameters";
    }


    #
    #  Prepare and execute the search
    #
    my $sql = $db->prepare($querystr);
    $sql->execute() or die $db->errstr();

    #
    #  Now bind the results.
    #
    my ( $username, $url, $realemail );
    $sql->bind_columns( undef, \$username, \$url, \$realemail );

    #
    #  The results we return.
    #
    my $resultsloop = [];

    #
    #  Process each result.
    #
    while ( $sql->fetch() )
    {
        push( @$resultsloop,
              {  username  => $username,
                 url       => $url,
                 realemail => $realemail,
              } );
    }
    $sql->finish();

    return ($resultsloop);
}



=head2 findUser

  Test to see whether the given user exists.

=cut

sub findUser
{
    my ( $class, %params ) = (@_);

    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();


    #
    #  The search parameters.
    #
    my $username = $params{ 'username' };
    my $email    = $params{ 'email' };


    #
    # Search by username
    #
    if ( defined($username) )
    {
        my $sql =
          $db->prepare("SELECT username,realemail FROM users WHERE username=?");
        $sql->execute($username);
        my ( $name, $mail ) = $sql->fetchrow_array();
        $sql->finish();

        if ( defined($name) &&
             defined($mail) )
        {
            return ( $name, $mail );
        }
    }
    if ( defined($email) )
    {
        my $sql = $db->prepare(
                      "SELECT username,realemail FROM users WHERE realemail=?");
        $sql->execute($email);
        my ( $name, $mail ) = $sql->fetchrow_array();
        $sql->finish();

        if ( defined($name) &&
             defined($mail) )
        {
            return ( $name, $mail );
        }
    }

    return ( undef, undef );
}


=head2 count

  Return the number of registered users.

=cut

sub count
{
    my ($class) = (@_);

    #
    #  Is this information cached?
    #
    my $cache = Singleton::Memcache->instance();
    my $count = $cache->get("user_count");
    if ( defined($count) )
    {
        return ($count);
    }


    #
    #  Get the database handle.
    #
    my $db = Singleton::DBI->instance();


    #
    #  The query.
    #
    my $querystr = "SELECT COUNT(username) FROM users";
    my $query    = $db->prepare($querystr);


    #
    # Execute
    #
    $query->execute();

    #
    # Get the result
    #
    $count = $query->fetchrow_array();

    #
    # Update the cache.
    #
    $cache->set( "user_count", $count );


    #
    # Cleanup.
    #
    $query->finish();

    return ($count);

}



=head2 exists

  Check whether the given username exists.

=cut

sub exists
{
    my ( $class, %parameters ) = (@_);

    #
    # Get the username.
    #
    my $username = $parameters{ 'username' } || $class->{ 'username' };


    die "No username " if ( !defined($username) );

    #
    # Get the database handle.
    #
    my $db = Singleton::DBI->instance();

    # query the database for just the username
    my $sql = $db->prepare("SELECT username FROM users WHERE username=?");
    $sql->execute($username);
    my @exists = $sql->fetchrow_array();
    my $exist  = $exists[0];
    $sql->finish();

    # return true if the user exists, false if they don't
    return 1 if $exist;
    return 0;
}



=head2 getRecent

  Return the most recent users to have joined.

=cut

sub getRecent
{
    my ( $class, $count ) = (@_);

    #
    #  Get access to singleton objects
    #
    my $db = Singleton::DBI->instance();

    my $sql = $db->prepare(
        "SELECT username,url,joined FROM users WHERE to_days(now()) - to_days(joined) <= ? ORDER BY joined"
    );

    # get required data
    $sql->execute($count) or die "Failed to run query: " . $db->errstr();

    # Bind comments for our results.
    my ( $username, $homepage, $joined );
    $sql->bind_columns( undef, \$username, \$homepage, \$joined );

    # The results we'll return to our users.
    my $users = [];

    while ( $sql->fetch() )
    {

        #
        # Get the number of comments this user has posted.
        #
        my $u = Yawns::User->new( username => $username );
        my $c = $u->getCommentCount();

        push( @$users,
              {  commentcount => $c,
                 username     => $username,
                 homepage     => $homepage,
                 joined       => $joined
              } );
    }

    return ($users);
}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
    my ($class) = (@_);

    #
    #  Flush the cached count of users.
    #
    my $cache = Singleton::Memcache->instance();
    $cache->delete("user_count");

}

1;
