#!/usr/bin/perl -w -Ilib/
#
#  Test that our XML output feeds are valid.
#
# $Id: xml-feed-validity.t,v 1.3 2007-03-08 10:10:08 steve Exp $
#

use Test::More ;

#
#  Conditionally decide whether to run or not.
#
if ( -d "/usr/local/validator" )
{
    plan no_plan;
}
else
{
    plan skip_all => "/usr/local/validator is not present" ;
}




#
#  Download some files from our site and make sure they are valid XML
#
foreach my $url ( qw!
                       /recent/comments
                       /recent/reported
                       /recent/reported/weblogs
                       /News/feed/
                       /submission/feed/
                       /comment/feed/onweblog/0
                       /comment/feed/onarticle/0
                       /comment/feed/onpoll/0
                       /weblog/feeds/Steve
                       /tag/feeds/fluffy
                       /tip/feed
                  ! )
{
    testURI( $url );
}







=head2 testURI

  Test an URI for feed well-formedness.

=cut

sub testURI
{
    my( $uri ) = (@_);

    my $cmd    = "/usr/local/validator/test.py  http://localhost" . $uri;
    my $output = `$cmd`;


    ok( $output =~ m/No errors/i, "The feed had no errors: $uri" );

}
