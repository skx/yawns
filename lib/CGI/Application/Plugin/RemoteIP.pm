
=head1 NAME

CGI::Application::Plugin::RemoteIP - Unified Remote IP handling

=head1 SYNOPSIS

  use CGI::Application::Plugin::RemoteIP;


  # Your application
  sub run_mode {
    my ($self) = ( @_);

    my $ip = $self->remote_ip();
  }

=cut


=head1 DESCRIPTION

This module simplifies the handling of the detection of the remote
IP address(es) of visitors.

=cut

=head1 MOTIVATION

This module allows you to remove scattered references in your code, such as:

=for example begin

    my $ip = $ENV{'REMOTE_ADDR'};
    $ip =~ s/^::ffff://g;
    ..

=for example end

Instead your code and use the simpler expression:

=for example begin

    my $ip = $self->remote_ip();

=for example end

The caveat, which is B<crucial> is that you must trust any proxies
en route if you wish to use the C<X-Forwarded-For> header.

=cut

use strict;
use warnings;

package CGI::Application::Plugin::RemoteIP;


our $VERSION = '0.1';


=head1 METHODS


=head2 import

Force the C<remote_ip> method into the caller's namespace.
=cut

sub import
{
    my $pkg     = shift;
    my $callpkg = caller;

    {
        ## no critic
        no strict qw(refs);
        ## use critic
        *{ $callpkg . '::remote_ip' } = \&remote_ip;
        *{ $callpkg . '::is_ipv6' }   = \&is_ipv6;
        *{ $callpkg . '::is_ipv4' }   = \&is_ipv4;
    }
}


=head2 remote_ip

Return the remote IP of the visitor, whether via the C<X-Forwarded-For> header
or via the standard CGI environmental variable C<REMOTE_ADDR>.

=cut

sub remote_ip
{
    my $cgi_app = shift;

    # X-Forwarded-For header is the first thing we look for.
    my $forwarded = $ENV{ 'HTTP_X_FORWARDED_FOR' };
    if ($forwarded)
    {

        # Split in case there are multiple values
        my @vals = split( /[ ,]/, $forwarded );

        if (@vals)
        {

            # Get the first/trusted value.
            my $ip = $vals[0];

            # drop IPv6 prefix
            $ip =~ s/^::ffff://gi;

            # Drop a port
            $ip =~ s/:([0-9]+)$//g;

            return $ip;
        }
    }

    # This should always work.
    my $ip = $ENV{ 'REMOTE_ADDR' };

    # drop IPv6 prefix
    $ip =~ s/^::ffff://gi;

    # Drop a port
    $ip =~ s/:([0-9]+)$//g;

    return ($ip);

}


=begin doc

Determine whether the remote IP address is IPv4.

=end doc

=cut

sub is_ipv4
{

    # Get the IP
    my $self = shift;
    my $ip   = $self->remote_ip();

    # Dotted quad?
    if ( $ip =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ )
    {
        return 1;
    }
    else
    {
        return 0;
    }
}


=begin doc

Determine whether the remote IP address is IPv6.

=end doc

=cut

sub is_ipv6
{

    # Get the IP
    my $self = shift;
    my $ip   = $self->remote_ip();

    # not IPv6 if IPv4
    return 0 if ( $ip =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ );

    # Not IPv6 unless it has a colon
    return 0 unless ( $ip =~ /:/ );

    # Probably OK
    return 1;
}



=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut



1;
