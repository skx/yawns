# -*- cperl -*- #

=head1 NAME

Yawns::Permissions - A module for working with user permissions.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Permissions;
    use strict;

    my $user = Yawns::Permissions->new( username => 'Steve');

    # Can the user delete a user?
    my $has_delete = $user->check( priv => "delete_user" );

    # can the user approve/edit/reject articles?
    my $has_approve = $user->check( priv => "article_admin" );

=for example end

=head1 DESCRIPTION

This module contains code for checking permissions of our site-users.

This code allows users to be tested for varying permission keys.  For
example before deleting a pending article we'd test that the caller has
the permission "article_admin" - if they do we can proceed, if not we
have an errant user.

The keys are deliberately text-based and cached since we assume that
< 1% of users will be privileged.

=cut

package Yawns::Permissions;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.13 $' =~ m/Revision:\s*(\S+)/;



#
#  Standard modules which we require.
#
use strict;
use warnings;


#
#  Yawns-specific modules we use.
#
use Singleton::DBI;



=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  These are the available permissions for checking.  The
    # value of the keys is irrelevant, we just store them in
    # a hash for easy lookup.
    #
    #  TODO:  Use an array.
    #
    my %known = (

        #
        #  Enable/Disable/Delete adverts.
        #
        advert_admin => 1,

        #
        #  Article approve/delete/edit.
        #
        article_admin => 1,

        #
        #  Edit static text.
        #
        edit_about => 1,

        #
        #  Can the user edit comments?
        #
        edit_comments => 1,

        #
        #  Can we edit the user information of an arbitary
        # user?
        #
        edit_user => 1,

        #
        #  Can we edit the permissions associated with a user?
        #
        edit_permissions => 1,

        #
        #  Edit/view the users scratchpad?
        #
        edit_user_pad => 1,

        #
        #  Can we edit the user preferences of an arbitary
        # user?
        #
        edit_user_prefs => 1,

        #
        #  Can we edit the notification options of an arbitary
        # user?
        #
        edit_notifications => 1,

        #
        #  Post comments without a slowdown?
        #
        fast_comments => 1,

        #
        #  Work with news items?
        #
        news_admin => 1,

        #
        #  Approve/reject delete polls.
        #
        poll_admin => 1,

        #
        #  Show recent users on the admin menu.
        #
        recent_users => 1,

        #
        #  Add/delete related links to articles
        #
        related_admin => 1,

        #
        #  Avoid the HTML filtering
        #
        raw_html => 1,

        #
        #  Send a site-memo to arbitary users.
        #
        send_message => 1,

        #
        #  Edit all users.
        #
        user_admin => 1,

        #
        #  Banish an IP, and all their comments.
        #
        ban_ip => 1,

    );

    #
    #  Store this list internally.
    #
    $self->{ 'priv_keys' } = \%known;


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



=head2 check

  Determine whether the specified user has the specified privilege.

=cut

sub check
{
    my ( $self, %params ) = (@_);

    my $username = $params{ 'username' } || $self->{ 'username' };
    my $priv     = $params{ 'priv' }     || $self->{ 'priv' };

    #
    #  Make sure we got something.
    #
    die "No username"      unless ( defined($username) );
    die "Nothing to check" unless ( defined($priv) );

    #
    #  Anonymous users have no special privileges.  Ever.
    #
    return 0 if ( $username =~ /^anonymous$/i );


    #
    #  Make sure we're checking a privilege we're expecting - this is
    # a guard against typos in the caller to this function.
    #
    my $found = 0;
    my $known = $self->{ 'priv_keys' };
    foreach my $key ( keys %$known )
    {
        $found += 1 if ( lc($priv) eq lc($key) );
    }

    #
    #  Abort on invalid string
    #
    die "Invalid permission check: '$priv'" unless ($found);


    #
    #  Get the database handle.
    #
    my $dbh = Singleton::DBI->instance();

    #
    #  Prepare the query
    #
    my $sql = $dbh->prepare(
        "SELECT username,permission FROM permissions WHERE username=? AND permission=?"
    );

    $sql->execute( $username, $priv ) or
      die "Failed to execute " . $dbh->errstr();
    my @thisuser = $sql->fetchrow_array();
    $sql->finish();

    #
    #  Get the result
    #
    my $result = 0;
    $result = 1 if ( $thisuser[0] );

    #
    #  Store in cache, and return.
    #
    return ($result);
}



=head2 findWith

  Find all the users with the given permission key.

=cut

sub findWith
{
    my ( $self, $key ) = (@_);

    #
    #  This information cannot easily be cached.
    #
    my $dbi = Singleton::DBI->instance();
    my $sql =
      $dbi->prepare("SELECT username FROM permissions WHERE permission=?");

    $sql->execute($key) or die $dbi->errstr();

    #
    #  Now bind the results.
    #
    my ($username);
    $sql->bind_columns( undef, \$username );

    #
    #  The results
    #
    my $results = [];

    while ( $sql->fetch() )
    {
        push( @$results, { username => $username } );
    }
    $sql->finish();

    #
    #  Return
    #
    return ($results);
}



=head2 getKnownAttributes

  Return all the currently used permission keys

  This is just used for testing right now, however it will be used to
 allow users with "grant_privileges" ability to edit other users.

=cut

sub getKnownAttributes
{
    my ( $self, $username ) = (@_);

    my $known = $self->{ 'priv_keys' };

    return ( keys(%$known) );
}


=head2 givePermission

  Grant the named user the specified permission key.

=cut

sub givePermission
{
    my ( $self, $username, $key ) = (@_);

    #
    #  Get the database handle.
    #
    my $dbh = Singleton::DBI->instance();

    #
    #  Prepare the SQL
    #
    my $sql = $dbh->prepare(
                 "INSERT INTO permissions (username,permission) VALUES( ?, ?)");
    $sql->execute( $username, $key );

    #
    #  All done
    #
    $sql->finish();

}



=head2 makeAdmin

  Make a user a *global* administrator.

=cut

sub makeAdmin
{
    my ( $self, $username ) = (@_);

    #
    #  Remove any prior privileges.
    #
    $self->removeAllPermissions($username);

    #
    #  Get all the currently used permission key names.
    #
    my $known = $self->{ 'priv_keys' };

    #
    #  Give the user each privilege in use.
    #
    foreach my $key ( keys %$known )
    {
        $self->givePermission( $username, $key );
    }

}



=head2 removeAllPermissions

  Remove all special permissions the user might have.

=cut

sub removeAllPermissions
{
    my ( $self, $username ) = (@_);

    #
    #  Get the database handle.
    #
    my $dbh = Singleton::DBI->instance();

    #
    #  Prepare and execute the SQL
    #
    my $sql = $dbh->prepare("DELETE FROM permissions WHERE username=?");

    $sql->execute($username) or
      die "Failed to remove permissions from $username" . $dbh->errstr();

    #
    #  All done
    #
    $sql->finish();

}



=head2 invalidateCache

  Clean any cached content we might have.

=cut

sub invalidateCache
{
}

#
#  return 1 so that Perl knows we loaded correctly.
#
1;
