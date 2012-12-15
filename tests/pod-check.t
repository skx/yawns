#!/usr/bin/perl -w
#
#  Test that the POD we include in our scripts is valid, via the external
# podcheck command.
#
# Steve
# --
# $Id: pod-check.t,v 1.2 2006-06-24 19:30:48 steve Exp $
#

use strict;
use File::Find;
use Test::More qw( no_plan );


find( { wanted => \&checkFile, no_chdir => 1 }, '.' );



#
#  Check a file.
#
#  If this is a perl file then call "perl -c $name", otherwise
# return
#
sub checkFile
{
    # The file.
    my $file = $File::Find::name;

    # We don't care about directories
    return if ( ! -f $file );

    # We have some false positives which fail our test but
    # are actually ok.  Skip them.
    my @false = qw( modules.sh user.utils articles search.cgi index.cgi ~ tests/ );

    foreach my $err ( @false )
    {
	return if ( $file =~ /$err/ );
    }

    # See if it is a perl file.
    my $isPerl = 0;

    # Read the file.
    open( INPUT, "<", $file );
    foreach my $line ( <INPUT> )
    {
        if ( $line =~ /\/usr\/bin\/perl/ )
        {
            $isPerl = 1;
        }
    }
    close( INPUT );

    #
    #  Files with a .pm, .cgi, and .t suffix are perl.
    #
    if ( ( $file =~ /\.pm$/ ) ||
         ( $file =~ /\.cgi$/ ) ||
         ( $file =~ /\.t$/ ) )
    {
        $isPerl = 1;
    }

    #
    #  Admin files are pod-free
    #
    if ( $file =~ /admin/i )
    {
        $isPerl = 0;
    }


    #
    #  Return if it wasn't a perl file.
    #
    return if ( ! $isPerl );


    ok( -e $file, "$file" );

    if ( ( -x $file ) && ( ! -d $file ) )
    {
        #
        #  Execute the command giving STDERR to STDOUT where we
        # can capture it.
        #
        my $cmd           = "podchecker $file";
        my $output = `$cmd 2>&1`;
        chomp( $output );

        is( $output, "$file pod syntax OK.", " File has correct POD syntax: $file" );
    }
}

