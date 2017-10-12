#
# lib/Application/Yawns caches all content that is rendered to the
# filesystem.
#
# This used to be done by writing to /tmp/$md5sum.cache, but that
# lead to thousands of files in a single directory (/tmp).
#
# Now we write to /tmp/x/y/$hash
#
# This module takes care of testing/creating the appropriate
# directories.
# 
#

package Yawns::Cache;

use strict;
use warnings;
use File::Path qw! make_path !;

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

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

sub exists
{
    my ($self) = (@_);

    my $hash = $self->{ 'hash' };
    if ( $hash =~ /^(.)(.)(.)(.)(.*)$/ )
    {
        my $path = "/tmp/$1/$2/$3/$4/$5";
        return ( -e $path );
    }
    return 0;


}

sub path
{
    my ( $self, $content ) = (@_);

    my $hash = $self->{ 'hash' };
    if ( $hash =~ /^(.)(.)(.)(.)(.*)$/ )
    {
        my $dir = "/tmp/$1/$2/$3/$4";
        my $path= "/tmp/$1/$2/$3/$4/$5";

        make_path( $dir,
                   {  verbose => 0,
                      mode    => 0755,
                   } )
          unless ( -d $dir );

        return ($path);
    }
    die "Missing hash?";
}

1;
