#!/usr/bin/env python
#
#  This is the fabric configuration file which deploys our codebase
# to the live location.
#
#  There are two real targets:
#
#   fab live
#      Deploy the codebase to the five-node cluster hosted on BigV
#    at Bytemark.  There are four web-nodes, along with a DB servers,
#    and one misc machine.
#
#   fab beta
#     Deploy the codebase to the single standalone node.
#
#  Both live and beta now run over IPv6.
#
# Steve
# --
#


from __future__ import with_statement

import os
import sys
import subprocess

try:
    from fabric.api import env, local, put, roles, run, settings
    from fabric.contrib.console import confirm
except ImportError:
    print ("""The 'fabric' package is currently not installed. You can install it by typing:\n
sudo apt-get install fabric
""")
    sys.exit()


#
# Define sets of servers as roles
#
env.roledefs = {
        'live': ['web1.vlan299.skx.uk0.bigv.io:2222',
                'web2.vlan299.skx.uk0.bigv.io:2222',
                'web3.vlan299.skx.uk0.bigv.io:2222',
                'web4.vlan299.skx.uk0.bigv.io:2222'],
        'beta': ['beta.vlan299.skx.uk0.bigv.io:2222' ]

}


#
#  Username to ssh as.
#
env.user = 'root'




#
#  Our live-targets.
#
@roles('live')
def live():
    """
    Deploy our codebase to our LIVE environment.
    """
    deploy( "./lib/conf/SiteConfig.pm.live" )


#
#  Our staging-target.
#
@roles('beta')
def beta():
    """
    Deploy our codebase to our two BETA nodes.
    """
    deploy( "./lib/conf/SiteConfig.pm.beta" )






#
# Deploy our application to an environment.
#
# The environment here doesn't matter because the hosts involved will be
# inferred from the callers "roles" decorator.
#
# The single parameter required is the name of the configuration file
# which should be deployed.
#
def deploy( config_file ):
    """
    Deploy the application to a given environment.

    Once installed upload the specified configuration file.
    """

    #
    #  Test the configuration file exists.
    #
    if not os.path.isfile(config_file):
        print "Configuration file not found:", config_file
        exit(1)


    #
    #  Upload the git repository to ~/releases/XXX, and symlink
    # ~/current to the most recent version.
    #
    #  Using a symlink ~/current allows quickish reverts if required.
    #
    _upload()

    #
    #  Place the configuration file into place.
    #
    put( config_file, "~/current/lib/conf/SiteConfig.pm" )

    #
    #  These should happen AFTER the configuration file has been uploaded,
    # as they might require access to the configuration file containing the
    # database connection details, etc.
    #
    _build_feeds()
    _build_templates()

    #
    #  Include any cron-jobs we might have.
    #
    _build_cron()

    #
    #  Include the resources for our articles.
    #
    _include_resources()

    #
    # Finally restart Apache
    #
    run( "/etc/init.d/apache2 restart", pty=True )







def _upload():
    """
    Tar the current git repository, upload it, and then cleanup.
    """

    #
    #  Find the current revision number.
    #
    id = [ S.strip('\n') for S in os.popen('git rev-parse HEAD').readlines() ]
    id = id[0]

    #
    #  Ensure the remote side is prepared.
    #
    with settings(warn_only=True):
        if run ("test -d ~/releases/%s" % id ).failed:
            run("mkdir -p ~/releases/%s" % id  )

    #
    # now tar & upload the current codebase.
    #
    local('git archive  --format tar -o %s.tar --prefix=%s/ HEAD' % ( id, id ) )
    put( "%s.tar" % id , "~/releases/"  )

    #
    #  Finally unpack the remote code.
    #
    run( "cd ~/releases && tar -xf %s.tar" %  id )

    #
    #  Now symlink in the current release
    #
    run( "rm ~/current || true" )

    run( "ln -s ~/releases/%s ~/current" % id )

    #
    #  Cleanup
    #
    run( "rm ~/releases/*.tar || true" )
    local( "rm %s.tar || true" % id )

    #
    #  Install any dependencies
    #
    run( "cd ~/current && ./bin/debian-dependencies" )



def _build_feeds():
    """
    Build the RSS feeds for the site.
    """
    run( "cd ~/current && make feeds", pty=True )


def _build_templates():
    """
    Build master HTML::Templates from our layout and page templates
    """
    run( "cd ~/current && ./bin/render-templates" )


def _build_cron():
    """
    Upload our crontab.  We have two jobs:

    1.  Rebuild our RSS feeds every two minutes, if changed.

    2.  Build our search indexes.
    """
    run( "cat ~/current/etc/cron/crontab | crontab -" )


def _include_resources():
    """
    Articles contain some static resources, such as images.

    These come from a git repository which should exist beneath the live
    htdocs directory at ~/current/htdocs/resources/
    """

    #
    # Ensure that the remote host has Git installed.
    #
    with settings(warn_only=True):
        if run ("test -x /usr/bin/git").failed:
            run("/usr/bin/apt-get install --yes --force-yes git")

    #
    #  Now fetch the actual articles.
    #
    run( "cd /root/current/htdocs/ ; git clone -c http.sslVerify=false --quiet http://git.steve.org.uk/git/yawns/resources.git resources/", pty=True )




#
#  This is our entry point.
#
if __name__ == '__main__':

    if len(sys.argv) > 1:
        #
        #  If we got an argument then invoke fabric with it.
        #
        subprocess.call(['fab', '-f', __file__] + sys.argv[1:])
    else:
        #
        #  Otherwise list our targets.
        #
        subprocess.call(['fab', '-f', __file__, '--list'])
