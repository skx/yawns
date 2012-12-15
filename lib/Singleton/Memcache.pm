
=head1 NAME

Singleton::Memcache - A singleton wrapper around Danga's memcache.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Singleton::Memcache;
    use strict;

    # Get the cache handle.
    my $cache = Singleton::Memcache->instance();

    # Set a value in the cache, and retrieve it.
    $cache->set( "bob", "your uncle" );
    $cache->get( "bob" );

    # Finally delete the key.
    $cache->delete( "bob" );

=for example end


=head1 DESCRIPTION


  This module implements a Singleton wrapper around Cache::Memcached,
 which allows global access to a running memcached instance.

  This singleton is a proxy object, which will attempt to create an
 object to forward requests to, and silently swallow requests if this
 creation fails.

  We will fail if:

   1.  The configuration file says we're disabled.
   2.  The <Cache::Memcached> Perl module isn't enabled, or otherwise
      fails to connect.

=cut

=head1 DISCUSSION

  For more discussion on the code, and why it is implemented in this
 manner you might be interested in the following node at Perlmonks:

   http://www.perlmonks.org/?node_id=507753

=cut



package Singleton::Memcache;


use strict;
use warnings;



#
#  Read configuration file to see if we're enabled.
#
use conf::SiteConfig;


#
#  The single, global, instance of this object
#
my $_cache;


#
#  The memcache instance we use.
#
my $_memcache;



=head2 instance

  Gain access to the cache instance.  If the singleton object has been
 created return it.  Otherwise create a new instance.

=cut

sub instance
{
    $_cache ||= (shift)->new();
}



=head2 new

  Constructor.  We connect to the cache, and store a reference to it
 internally.

  If the cache is disabled in the configuration file then we do nothing,
 similarly if the creation of the cache connection fails then we
 just quietly disable ourself.

=cut

sub new
{
    my ($self) = (@_);

    my $class = ref($self) || $self;

    #
    #  See if we're enabled
    #
    my $test    = "use Cache::Memcached;";
    my $enabled = conf::SiteConfig::get_conf('memcached');

    #
    #  The configuration file says we're enabled.
    #
    if ($enabled)
    {

        #
        #  Test loading the Cache module, if it fails then
        # the cache isn't enabled regardless of what the
        # configuration file says.
        #
        eval($test);
        if ($@)
        {
            $enabled = 0;
        }
    }

    #
    # Connect
    #
    if ($enabled)
    {
        $_memcache = new Cache::Memcached { 'servers' => ["localhost:11211"] };
    }

    return bless {}, $class;
}



=head2 disconnect

  Disconnect from the cache

=cut

sub disconnect
{
    my ( $self, @rest ) = (@_);

    $_memcache->disconnect_all(@rest) if defined($_memcache);
}



=head2 get

  Get a key from the cache

=cut

sub get
{
    my ( $self, $name, @rest ) = (@_);

    # lowercase
    $name = lc($name) if ($name);

    $_memcache->get( "xx" . $name, @rest ) if defined($_memcache);
}



=head2 set

  Set a key in the cache.  Note that we'll get a warning from Perl
 if we attempt to set an undefined value.

  We could catch it here, but we do not.

=cut

sub set
{
    my ( $self, $name, @rest ) = (@_);

    # lowercase
    $name = lc($name) if ($name);

    $_memcache->set( "xx" . $name, @rest ) if defined($_memcache);
}


=head2 stats

  Return statistic information about the current server.

=cut

sub stats
{
    my ( $self, @rest ) = (@_);

    $_memcache->stats(@rest) if defined($_memcache);
}



=head2 delete

  Delete a key from the cache.

=cut

sub delete
{
    my ( $self, $name, @rest ) = (@_);

    # lowercase
    $name = lc($name) if ($name);

    $_memcache->delete( "xx" . $name, @rest ) if defined($_memcache);
}


1;


=head1 AUTHOR

Steve Kemp

http://www.steve.org.uk/

=cut



=head1 LICENSE

Copyright (c) 2005-2007 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut
