#!/usr/bin/perl -w -I../lib/ -I./lib/

=head1 NAME

ajax.cgi - Backend routines for AJAX access.

=cut

=head1 AUTHOR

 Steve
 --
 http://www.steve.org.uk/

 $Id: ajax.cgi,v 1.24 2007-03-07 20:34:19 steve Exp $

=cut

=head1 LICENSE

Copyright (c) 2005-2006 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut



# Enforce good programming practices
use strict;
use warnings;


# UTF is the way of the future.
use utf8;
binmode STDOUT, ":utf8";

#
#  Singleton objects we create and use
#
use Singleton::DBI;
use Singleton::CGI;
use Singleton::Session;

#
# standard perl modules
#
use CGI::Cookie;
use HTML::Template;

#
# Yawns modules we use.
#
use HTML::AddNoFollow;
use Yawns::Formatters;
use Yawns::Messages;
use Yawns::Permissions;
use Yawns::Preferences;
use Yawns::Submissions;
use Yawns::Tags;



# ===========================================================================
# Make an initial database connection, to make the singleton live.
# ===========================================================================

my $db = Singleton::DBI->instance();

if ( !$db )
{
    print "Content-type: text/plain\n\n";
    print "Cannot connect to database.";
    exit;
}


# ===========================================================================
# Gain access to any parameters from URL and any submitted form.
# ===========================================================================
my $form = Singleton::CGI->instance();


# ===========================================================================
# Setup the session object for the code, only lasting a week.
# ===========================================================================
my $session = Singleton::Session->instance();
$session->expires("+7d");


# ===========================================================================
# The sessions will be handled by our clients as a cookie.  Expire it at the
# same time as our session actually epires.
# ===========================================================================
my $sessionCookie = $form->cookie( -name    => 'SESS',
                                   -value   => $session->id,
                                   -expires => '+1d'
                                 );



# ===========================================================================
#  We require a login for most AJAX operations.
# ===========================================================================
my $username = $session->param("logged_in") || "Anonymous";
my $anonymous = 0;

$anonymous = 1 if ( $username =~ /^anonymous$/i );



#
#  Make sure our sessions cookie is served in all cases.
#
print "Set-Cookie: $sessionCookie; HttpOnly\n";


# ===========================================================================
#  Iterate over all the submitted form parameters, and sanitize them.
#
#  We trust administrators, so they don't get scrubbed.
# ===========================================================================
my $perms = Yawns::Permissions->new( username => $username );
if ( !$perms->check( priv => "raw_html" ) )
{
    $form = HTML::AddNoFollow::sanitize($form);
}



# ===========================================================================
#
# Dispatch handlers.
#
# ===========================================================================
my %dispatch = (
                 "add_submission_note" => {
                           sub   => \&add_submission_note,
                           login => 1,
                           type => "Content-Type: text/html; charset=UTF-8\n\n",
                 },
                 "add_tag" => {
                           sub   => \&add_tag,
                           login => 1,
                           type => "Content-Type: text/html; charset=UTF-8\n\n",
                 },
                 "tag_complete" => {
                           sub  => \&tag_complete,
                           type => "Content-Type: text/html; charset=UTF-8\n\n",
                 },
                 "get_message" => { sub   => \&get_message,
                                    login => 1,
                                    type  => "Content-type: text/plain\n\n",
                                  },
                 "get_recent_tags" => {
                           sub  => \&get_recent_tags,
                           type => "Content-Type: text/html; charset=UTF-8\n\n",
                 },
                 "get_tags" => {
                           sub  => \&get_tags,
                           type => "Content-Type: text/html; charset=UTF-8\n\n",
                 },
                 "set_format" => { sub   => \&set_posting_format,
                                   login => 1,
                                   type  => "Content-type: text/plain\n\n",
                                 },
               );



#
#  Examine the submitted parameters and dispatch control to the appropriate
# routine.
#
foreach my $key ( $form->param() )
{

    #
    #  See if the parameter is in our dispatch table.
    #
    my $match = $dispatch{ $key };

    #
    #  If it is we can use it.
    #
    if ($match)
    {

        #
        #  Print error if we require a login, and we've
        # got an anonymous user.
        #
        if ( ( $match->{ 'login' } ) && ($anonymous) )
        {

            # Show error.
            print "Content-type: text/plain\n\n";
            print "You must be logged in to use this AJAX facility.\n";
        }
        else
        {

            #
            #  Print the appropriate content type.
            #
            print $match->{ 'type' } if ( $match->{ 'type' } );

            #
            #  Now call the function.
            #
            $match->{ 'sub' }->();
        }

        #
        #  Cleanup and exit since each incoming request will only
        # do one thing.
        #
        $session->close();
        $db->disconnect();
        exit;
    }
}



#
#  If we didn't get handled then we've either been invoked by something
# that is obsolete, or manually.
#
print $form->header(
                -type     => 'text/html',
                -cookie   => $sessionCookie,
                -location => => "http://" . $ENV{ "SERVER_NAME" } . "/about/404"
);


#
#  All done, clean up session and database then exit.
#
$session->close();
$db->disconnect();
exit;



=head2 add_submission_note

  Add a new note upon a submission

=cut

sub add_submission_note
{
    my $id   = $form->param("id");
    my $note = $form->param("note");

    die "No ID"   unless defined($id);
    die "No note" unless defined($note);


    #
    #  Add the note
    #
    my $queue = Yawns::Submissions->new();
    $queue->addSubmissionNote( submission => $id,
                               note       => $note,
                               username   => $username
                             );

    #
    #  Show the current notes.
    #
    my $new = $queue->getSubmissionNotes($id);

    #
    #  Load the template and output it.
    #
    my $template =
      HTML::Template->new(
                   filename => "../templates/includes/submission-notes.template" );
    $template->param( submission_notes => $new );
    print $template->output();
}



=head2 add_tag

  Called to add a tag to either an article, a submission, a poll, or
 a weblog.

=cut

sub add_tag
{

    #
    # Get the data from the submission.
    #
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
                                 loop_context_vars => 1 );

    $template->param( tags => $tags ) if defined($tags);

    #
    #  Show the template.
    #
    print $template->output();
}


=head2 tag_complete

  Complete against all the tags ever used.

=cut

sub tag_complete
{

    #
    #  Get the completion version and ensure it is present.
    #
    my $q = $form->param("q");
    if ( !defined($q) || !length($q) )
    {
        return;
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
    foreach my $key ( keys(%valid) )
    {
        print "$key|$key\n";
    }

}


=head2 get_recent_tags

  Fetch the most recently added tags.

=cut

sub get_recent_tags
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
    print $template->output();
}



=head2 get_tags

  Return all the tags upon our site of a particular kind.

=cut

sub get_tags
{

    #
    #  Get the type of tags.
    #
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
            print "Unknown tag type '$type'.";
            return;
        }
    }

    my $tags = $holder->getAllTagsByType($type);

    #
    #  Load the template
    #
    my $template =
      HTML::Template->new( filename => "../templates/includes/all_tags.template" );

    $template->param( all_tags => $tags ) if ($tags);
    print $template->output();
}



=head2 get_message

  Get and return a user-message

=cut

sub get_message
{

    #
    #  Get the ID of the message.
    #
    my $id = $form->param("get_message");

    #
    #  Fetch the message, and mark it as read.
    #
    my $msgs = Yawns::Messages->new( username => $username );
    my $text = $msgs->getMessage($id);
    $msgs->markRead($id);

    print @$text[0]->{ 'text' } . "\n";
}



=head2 set_posting_format

  Save the users posting format.

=cut

sub set_posting_format
{

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
        print "$desc preference saved.\n";
        return;
    }

    #
    #  Naughty.
    #
    $format = HTML::Entities::encode_entities($format);
    print "Invalid posting format '$format'.\n";
}
