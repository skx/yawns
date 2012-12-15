
#!/usr/bin/perl -w
#
#  Test that all the site templates we use have the long-form for the
# HTML Templates.
#
#  Also attempt to load each template so that HTML::Template will complain
# if they are not well-formed.
#
# $Id: templates.t,v 1.7 2006-05-09 14:32:04 steve Exp $
#

use Test::More qw( no_plan );
use File::Find;


#
#  Load the module.
#
BEGIN { use_ok( 'HTML::Template'); }
require_ok( 'HTML::Template' );


#
#  Search for templates within the subdirectory templates/
#
find( { wanted => \&wanted, no_chdir => 1 }, "templates/" );


#
#  Called as a result of File::Find
#
sub wanted
{
    my $file = $File::Find::name;

    if ( ( $file =~ /.template$/ ) ||
         ( $file =~ /.inc$/ ) )
    {
        next if ( $file =~ /layouts/ );
	my $count = processFile( $file );
	ok( $count == 0, "Template file $file" );

	my $template = HTML::Template->new( filename => $file );
	isa_ok( $template, "HTML::Template" );
    }



}


#
# Test the template tags in the named file.
#
sub processFile
{
    my $template = shift;
    my $count    = 0;

    #
    # Open file.
    #
    open( INPUT, "<", $template )
      or die "Cannot open file '$template' for reading - $!";

    #
    # Build up a count of the <tmpl_*> tags.
    #
    foreach my $line ( <INPUT> )
    {
        $count ++ if ( $line =~ /<tmpl(.*)>/ );
    }

    close( INPUT );


    return( $count );
}
