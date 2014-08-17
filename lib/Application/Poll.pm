#
# This is a CGI::Application class which is designed to handle
# our polls.
#


#
# Hierarchy.
#
package Application::Poll;
use base 'CGI::Application';


#
# Standard module(s)
#
use HTML::Template;

#
# Our code
#
use conf::SiteConfig;



=begin doc

Setup - Just setup UTF.

=end doc

=cut

sub cgiapp_init
{
    binmode STDIN,  ":encoding(utf8)";
    binmode STDOUT, ":encoding(utf8)";
}




=begin doc

Called when an unknown mode is encountered.

=end doc

=cut

sub unknown_mode
{
    my ( $self, $requested ) = (@_);

    $requested =~ s/<>/_/g;

    return ("mode not found $requested");
}




=begin doc

Setup our run-mode mappings, and the defaults for the application.

=end doc

=cut

sub setup
{
    my $self = shift;

    $self->error_mode('my_error_rm');
    $self->run_modes(

        # debug
        'debug' => 'debug',

        # called on unknown mode.
        'AUTOLOAD' => 'unknown_mode',
    );

    #
    #  Start mode + mode name
    #
    $self->header_add( -charset => 'utf-8' );
    $self->start_mode('debug');
    $self->mode_param('mode');

}


sub my_error_rm
{
    my ( $self, $error ) = (@_);

    use Data::Dumper;
    return Dumper( \$error );
}


#
#  Handlers
#
sub debug
{
    return ("OK");
}




1;
