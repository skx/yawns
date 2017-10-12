
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

sub _path
{
    my ( $self, $name ) = (@_);

    if ( $name =~ /^(.)(.)(.*)/ )
    {
        my $dir  = "/tmp/$1/$2";
        my $path = "/tmp/$1/$2/$3";

        make_path( $dir,
                   {  verbose => 0,
                      mode    => 0755,
                   } )
          unless ( -d $dir );

    }
}

sub exists
{
    my ($self) = (@_);

    my $hash = $self->{ 'hash' };

    if ( $hash =~ /^(.)(.)(.*)$/ )
    {
        my $path = "/tmp/$1/$2/$3";
        return ( -e $path );
    }
    return 0;


}

sub path
{
    my ( $self, $content ) = (@_);

    my $hash = $self->{ 'hash' };

    if ( $hash =~ /^(.)(.)(.*)$/ )
    {
        my $dir  = "/tmp/$1/$2";
        my $path = "/tmp/$1/$2/$3";

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
