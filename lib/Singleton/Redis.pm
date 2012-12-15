
=head1 NAME

Singleton::Redis - A singleton wrapper around redis

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Singleton::Redis;
    use strict;

    # Get the cache handle.
    my $cache = Singleton::Redis->instance();

    # Set a value in the cache, and retrieve it.
    $cache->set( "bob", "your uncle" );
    $cache->get( "bob" );

    # Finally delete the key.
    $cache->delete( "bob" );

=for example end


=head1 DESCRIPTION

 This module implements a Singleton wrapper around Redis, and
allows global access to a running memcached instance.

 This singleton is a proxy object, which will attempt to create an
object to forward requests to, and silently swallow requests if this
creation fails.

=cut

package Singleton::Redis;


use strict;
use warnings;
use Redis;


#
#  Read configuration file to see if we're enabled.
#
use conf::SiteConfig;


#
#  The single, global, instance of this object
#
my $_cache;


#
#  The Redis instance we use.
#
my $_redis;



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
    my $test    = "use Redis;";
    my $enabled = conf::SiteConfig::get_conf('redis') || 0;

    #
    #  The configuration file says we're enabled.
    #
    if ($enabled)
    {
        #
        #  Test loading the module, if it fails then redis isn't
        # enabled regardless of what the configuration file says.
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
        $_redis = new Redis();
    }

    return bless {}, $class;
}



=head2 disconnect

  Disconnect from the cache

=cut

sub disconnect
{
    my ( $self, @rest ) = (@_);

    $_redis->quit() if defined($_redis);
}



=head2 get

  Get a key from the cache

=cut

sub get
{
    my ( $self, $name ) = (@_);

    # lowercase
    $name = lc($name) if ($name);

    $_redis->get( $name ) if defined($_redis);
}



=head2 set

  Set a key in the cache.  Note that we'll get a warning from Perl
 if we attempt to set an undefined value.

  We could catch it here, but we do not.

=cut

sub set
{
    my ( $self, $name, $val ) = (@_);

    # lowercase
    $name = lc($name) if ($name);

    $_redis->set( $name => $val ) if defined($_redis);
}


=head2 del

  Delete a key from the cache.

=cut

sub del
{
    my ( $self, $name ) = (@_);

    # lowercase
    $name = lc($name) if ($name);

    $_redis->del( $name ) if defined($_redis);
}

sub delete
{
    my( $self, $name ) = ( @_);
    return( $self->del($name));
}

=head2 expire

  Expire a key from the cache.

=cut

sub expire
{
    my ( $self, $name, $time ) = (@_);

    # lowercase
    $name = lc($name) if ($name);

    $_redis->expire( $name, $time ) if defined($_redis);
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
