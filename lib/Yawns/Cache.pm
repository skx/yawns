# -*- cperl -*- #

=head1 NAME

Yawns::Cache - A module for flushing our cache.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w

    use Yawns::Cache;
    use strict;

    #
    #  Get handle
    #
    my $obj = Yawns::Cache->new();
    $obj->flush( "reason for flush" );


=for example end


=head1 DESCRIPTION

This module allows our site-wide cache to be flushed.

=cut


package Yawns::Cache;

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


use Yawns::Event;


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

Flush the cache, and alert on why it was flushed.

=cut

sub flush
{
    my ( $class, $msg ) = (@_);

    #
    #  Flush the cache.
    #
    my $cmd = "/root/current/bin/expire-varnish";
    system("$cmd >/dev/null 2>&1 &");

    #
    #  Get the default reason why we flushed.
    #
    $msg = "Unknown reason!" if ( !defined($msg) );

    #
    #  Send the alert.
    #
    my $obj = Yawns::Event->new();
    $obj->send("Varnish cache flush: $msg");

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
