# -*- cperl -*- #

=head1 NAME

Yawns::Event - A module for sending event messages.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Event;
    use strict;

    #
    #  Get handle
    #
    my $obj = Yawns::Event->new();
    $obj->send( "new user" );


=for example end


=head1 DESCRIPTION

This module allows the sending of arbitrary "events".  Events are nothing more
than simple text strings which are sent to a central event-service, where they
may be viewed in chronological order via a simple display.

The intention is that the event-viewer will show "significant" activity from
the installation of Yawns.

=cut


=head2 EVENT SERVER

The event-server is not contained within the Yawns codebase, instead it
has its own repository:

http://git.steve.org.uk/yawns/events

=cut


package Yawns::Event;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw();

($VERSION) = '$Revision: 1.8 $' =~ m/Revision:\s*(\S+)/;


#
#  Standard modules which we require.
#
use strict;
use warnings;

use IO::Socket;
use conf::SiteConfig;


=head2 new

  Create a new instance of this object.

=cut

sub new
{
    my ( $self, %supplied ) = (@_);

    my $class = ref($self) || $self;

    return bless {}, $class;
}



=head2 send

Send an event message.

=cut

sub send
{
    my ( $class, $msg ) = (@_);

    #
    #  Get the event-server
    #
    my $endpoint = get_conf("event_endpoint") || "";

    if ( $endpoint =~ /^(udp|tcp):\/\/([^:]+):?([0-9]+)?$/i )
    {
        my $proto = lc($1);
        my $host  = $2;
        my $port  = $3 || 4433;

        my $sock = IO::Socket::INET->new( Proto    => $proto,
                                          PeerPort => $port,
                                          PeerAddr => $host
          ) or
          return;


        #
        #  Send the computed values
        #
        $sock->send($msg);
    }
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
