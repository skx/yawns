package Application::Base;
use base 'CGI::Application';

=begin doc

Setup UTF-8 and nothing else.

=end doc

=cut

sub cgiapp_init
{
    binmode STDIN,  ":encoding(utf8)";
    binmode STDOUT, ":encoding(utf8)";
}



1;
