# -*- cperl -*- #

=head1 NAME

Yawns::Date - A simple collection of date utility functions.

=head1 SYNOPSIS

=for example begin

    #!/usr/bin/perl -w
    use Yawns::Date;
    use strict;

=for example end



=head1 DESCRIPTION

A random assortment of utliity functions for working with dates.

=cut


package Yawns::Date;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA    = qw(Exporter AutoLoader);
@EXPORT = qw(
  convert_date_to_site get_iso_date get_str_date
  );

($VERSION) = '$Revision: 1.4 $' =~ m/Revision:\s*(\S+)/;



#
#  Standard modules which we require.
#
#
use strict;
use warnings;
use POSIX qw/ strftime /;    # time/date string handling functions



#
#  Yawns modules which we use.
#


# Parameters used by strftime (and returned by gmtime)
#    0    1    2     3     4    5    (6)   (7)
# ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday)

# convert the ISO date format used in the database to a nice string format,
# with date and time seperated
sub convert_date_to_site
{

    #
    #  Disable warnings for this subroutine.
    #
    no warnings;

    my $both     = $_[0];
    my $postdate = $both;
    my $posttime = $both;

    $postdate =~ m/(\d\d\d\d)-(\d\d)-(\d\d)/;

    my $d = $3;
    my $m = $2 - 1;
    my $y = $1 - 1900;
    $d =~ s/^ //;

    $posttime =~ m/(\d\d):(\d\d):(\d\d)/;
    $posttime = "$1:$2";

    $postdate = strftime( "%a %e %b %Y", $3, $2, $1, $d, $m, $y );

    return ( ( $postdate, $posttime ) );
}



#
# get the current date in the ISO format used by the database
#
sub get_iso_date
{
    my $iso_date = strftime( "%Y-%m-%d %H:%M:%S", localtime );
    return ($iso_date);
}


#
# get the current date and time in the string format used on the site
#
sub get_str_date
{
    my $datestr = strftime( "%a %e %b %Y", localtime );
    my $timestr = strftime( "%H:%M",       localtime );
    return ( ( $datestr, $timestr ) );
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
