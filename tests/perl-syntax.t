#!/usr/bin/perl -w
#
#  Test that every perl file we have passes the syntax check.
#
# Steve
# --
# $Id: perl-syntax.t,v 1.5 2006-09-04 05:31:19 steve Exp $


use strict;
use File::Find;
use Test::More qw( no_plan );


#
#  Find all the files beneath the current directory,
# and call 'checkFile' with the name.
#
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
    return if ( $file =~ /(\.hg|\.git)/ );
    return if ( $file =~ /\/articles\// );
    return if ( $file =~ /\/tests-lib\// );

    # We have some false positives which fail our test but
    # are actually ok.  Skip them.
    my @false = qw( search.cgi modules.sh user.utils ~ pod webalizer.current Makefile xml-feeds.t );

    foreach my $err ( @false )
    {
	return if ( $file =~ /$err/ );
    }

    # See if it is a perl file.
    my $isPerl = 0;

    # If the file has a '.pm' or '.cgi' suffix it is automatically perl.
    $isPerl = 1 if ( $file =~ /\.pm$/ );
    $isPerl = 1 if ( $file =~ /\.cgi$/ );

    # Read the file if we have to.
    if ( ! $isPerl )
    {
	open( INPUT, "<", $file );
	foreach my $line ( <INPUT> )
	{
	    if ( $line =~ /\/usr\/bin\/perl/ )
	    {
		$isPerl = 1;
	    }
	}
	close( INPUT );
    }

    #
    #  Return if it wasn't a perl file.
    #
    return if ( ! $isPerl );

    #
    #  Now run 'perl -c $file' to see if we pass the syntax
    # check.
    #
    my $retval = system( "perl -Ilib/ -c $file 2>/dev/null >/dev/null" );


    is( $retval, 0, "Perl file passes our syntax check: $file" );
}
