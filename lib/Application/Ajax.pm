#
# This is a CGI::Application class which is designed to handle
# our Ajax requests.
#
#


use strict;
use warnings;


#
# Hierarchy.
#
package Application::Ajax;
use base 'CGI::Application';

#
# Standard module(s)
#
use CGI::Session;
use Cache::Memcached;


#
# Our code
#
use conf::SiteConfig;
use Yawns::Tags;
use Yawns::Formatters;


=begin doc

Called on-error

=end doc

=cut

sub my_error_rm
{
    my ( $self, $error ) = (@_);

    use Data::Dumper;
    return Dumper( \$error );
}




=begin doc

Setup - Just setup UTF.

=end doc

=cut

sub cgiapp_init
{
    my $self  = shift;
    my $query = $self->query();

    #
    #  Get the cookie if we have one.
    #
    my $cookie_name   = 'CGISESSID';
    my $cookie_expiry = '+7d';
    my $sid           = $query->cookie($cookie_name) || undef;

    #
    #  Create the object
    #
    if ($sid)
    {
        my $dbserv = conf::SiteConfig::get_conf('dbserv');
        $dbserv .= ":11211";

        my $mem = Cache::Memcached->new( { servers => [$dbserv],
                                           debug   => 0
                                         } );

        my $session = CGI::Session->new( "driver:memcached", $query,
                                         { Memcached => $mem } );


        #
        # assign the session object to a param
        #
        $self->param( session => $session );
    }


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

    return ("mode not found: $requested");
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

        # Get tags of a particular type
        'get_tags' => 'get_tags',

        # Recent additions
        'recent_tags' => 'recent_tags',

        # Complete a tag
        'tag_complete' => 'tag_complete',

        # Add a tag
        'add_tag' => 'add_tag',

        # Set the posting format
        'set_format' => 'set_format',

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


#
#  Handlers
#
sub debug
{
    my ($self) = (@_);

    my $username = "Anonymous";

    my $session = $self->param('session');
    if ($session)
    {
        $username = $session->param("logged_in") || "Anonymous";
    }
    return ("OK - $username");
}



=head2 get_recent_tags

Fetch the most recently added tags.

=cut

sub recent_tags
{

    #
    # Get the tag object, and add the tag
    #
    my $holder = Yawns::Tags->new();
    my $recent = $holder->getRecent();

    #
    # Show the tags.
    #
    my $template = HTML::Template->new(
                       filename => "../templates/includes/recent_tags.template",
                       loop_context_vars => 1 );

    $template->param( recent_tags => $recent ) if defined($recent);

    #
    #  Show the template.
    #
    return( $template->output() );
}



=head2 get_tags

Return all the tags upon our site of a particular kind.

=cut

sub get_tags
{
    my( $self ) = ( @_ );

    #
    #  Get the type of tags.
    #
    my $form = $self->query();
    my $type = $form->param("type");


    #
    #  Get the tag holder
    #
    my $holder = Yawns::Tags->new();

    #
    #  If there is a type then it must be valid.
    #
    if ( defined($type) )
    {
        my $found = 0;

        foreach my $t ( $holder->getTagTypes() )
        {
            $found += 1 if ( $t eq $type );
        }

        #
        #  Unknown?
        #
        if ( !$found )
        {
            $type = HTML::Entities::encode_entities($type);
            return( "Unknown tag type '$type'." );
        }
    }

    my $tags = $holder->getAllTagsByType($type);

    #
    #  Load the template
    #
    my $template =
      HTML::Template->new(
                        filename => "../templates/includes/all_tags.template" );

    $template->param( all_tags => $tags ) if ($tags);
    return($template->output());
}


=head2 tag_complete

  Complete against all the tags ever used.

=cut


sub tag_complete
{

    my( $self ) = ( @_ );

    #
    #  Get the type of tags.
    #
    my $form = $self->query();

    #
    #  Get the completion version and ensure it is present.
    #
    my $q = $form->param("q");
    if ( !defined($q) || !length($q) )
    {
        return "";
    }

    #
    #  Get all tags
    #
    my $holder = Yawns::Tags->new();
    my $all    = $holder->getAllTags();

    my %valid;

    #
    #  Build a hash of their names.
    #
    foreach my $t (@$all)
    {
        my $name = $t->{ 'tag' };
        $valid{ $name } = 1 if ( $name =~ /\Q$q\E/i );
    }

    #
    #  Print matching ones.
    #
    my $str = "";
    foreach my $key ( keys(%valid) )
    {
        $str .= "$key|$key\n";
    }

    return( $str );
}



=head2 add_tag

  Called to add a tag to either an article, a submission, a poll, or
 a weblog.

=cut

sub add_tag
{
    my( $self ) = ( @_ );

    #
    #  Ensure we have a logged-in-user
    #
    my $session = $self->param('session');
    my $username = undef;
    if ($session)
    {
        $username = $session->param("logged_in") || undef;
        return( "Login Required" ) unless( $username );
    }


    #
    # Get the data from the submission.
    #
    my $form = $self->query();

    my $tag        = $form->param("new_tag");
    my $article    = $form->param("article") || undef;
    my $poll       = $form->param("poll") || undef;
    my $tip        = $form->param("tip") || undef;
    my $submission = $form->param("submission") || undef;
    my $weblog     = $form->param("weblog") || undef;

    #
    #  The tag holder
    #
    my $holder = Yawns::Tags->new();

    #
    #  Is the tag comma-separated?
    #
    foreach my $t ( split( /,/, $tag ) )
    {

        # ignore empty ones
        next if ( ( !$t ) || ( !length($t) ) );

        # strip space
        $t =~ s/^\s+|\s+$//g;

        # ignore empty ones
        next if ( ( !$t ) || ( !length($t) ) );

        #
        # Get the tag object, and add the tag
        #
        $holder->addTag( username   => $username,
                         article    => $article,
                         poll       => $poll,
                         tip        => $tip,
                         submission => $submission,
                         weblog     => $weblog,
                         tag        => $t
                       );
    }

    #
    # Get the (updated) tags upon the article, poll, submission or weblog.
    #
    my $tags = $holder->getTags( article    => $article,
                                 poll       => $poll,
                                 submission => $submission,
                                 tip        => $tip,
                                 weblog     => $weblog
                               );


    #
    # Load the tag template, to return the updated tags.
    #
    my $template = HTML::Template->new(
                                       filename => "../templates/includes/tags.template",
                                       loop_context_vars => 1
                                      );

    $template->param( tags => $tags ) if defined($tags);

    #
    #  Show the template.
    #
    return($template->output() );
}






=head2 set_format

Save the users posting format.

=cut

sub set_format
{

    my( $self ) = ( @_ );

    #
    #  Ensure we have a logged-in-user
    #
    my $session = $self->param('session');
    my $username = undef;
    if ($session)
    {
        $username = $session->param("logged_in") || undef;
        return( "Login Required" ) unless( $username );
    }


    #
    # Get the data from the submission.
    #
    my $form = $self->query();

    #
    #  Get the format
    #
    my $format = $form->param("format");

    #
    #  Get all formats
    #
    my $accessor = Yawns::Formatters->new();
    my %avail    = $accessor->getAvailable();

    #
    #  If the format is one that we know about save it
    # away.
    #
    my $desc = $avail{ lc($format) };

    if ( defined($desc) )
    {

        #
        #  Set the preference.
        #
        my $prefs = Yawns::Preferences->new( username => $username );
        $prefs->setPreference( "posting_format", $format );

        #
        # NOTE: We don't need to entity-encode the description,
        #       since it must have been one of our valid ones
        #       and they are exclusively ASCII.
        #
        return( "$desc preference saved.\n" );
    }

    #
    #  Naughty.
    #
    $format = HTML::Entities::encode_entities($format);
    return( "Invalid posting format '$format'.\n" );
}

1;
