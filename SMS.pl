#!/usr/bin/perl -s
#
## Shownotes Message Service

use strict;
use warnings;
use utf8;

use Log::Log4perl qw(:easy);

use Data::Dumper;
use Config::Simple;
use File::Basename;

use DBI;

use Net::XMPP;
use JSON;

# make a new config config object
my $currentpath = dirname(__FILE__);
my $cfg         = new Config::Simple("$currentpath/sms.config");

# some global variables
my $programpath = $cfg->param('directory');
my $account     = '';
my $msg         = "";
my $syn         = 0;
my $fin         = 0;
# Log config
Log::Log4perl->init("$currentpath/logging.config");

# connect to database
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$programpath/data.db",
    "",
    "",
    { RaiseError => 1 },    #Exceptions instead of error
) or die $DBI::errstr;

$dbh->do("PRAGMA foreign_keys = ON");

# create Subscription table if not exists
$dbh->do(
    "CREATE TABLE IF NOT EXISTS subscriptions(
                jid TEXT NOT NULL,
                slug TEXT NOT NULL,
                timestamp INT NOT NULL,
                UNIQUE (jid,slug)
        )"
);

# create Subscribers table if not exists
$dbh->do(
    "CREATE TABLE IF NOT EXISTS subscribers(
                jid TEXT NOT NULL,
                servicehost TEXT NOT NULL,
                token TEXT DEFAULT 0,
                challenge TEXT DEFAULT 0,
                UNIQUE (jid,servicehost)
        )"
);

# create pad info table if not exists
$dbh->do(
    "CREATE TABLE IF NOT EXISTS padinfo(
                jid TEXT NOT NULL PRIMARY KEY,
                info INT NOT NULL DEFAULT 0
        )"
);

# make a jabber client object
my $con = new Net::XMPP::Client();

# set the callback functions
$con->SetMessageCallBacks( chat => \&message );
$con->SetCallBacks( onauth => \&send_status );
$con->SetPresenceCallBacks( type => undef );

# execute jabber client
$con->Execute(
    hostname => $cfg->param('server'),
    port     => $cfg->param('port'),
    username => $cfg->param('username'),
    password => $cfg->param('password'),
    resource => $cfg->param('botresource')
);

# status update callback
sub send_status {
    INFO("Authenticated");
    print "Authenticated - Service is running";
    $con->PresenceSend( show => "chat" );
}

# callback for message handle
sub message {

    # get informations about the client, who is connected
    my ( $sid, $Mess ) = @_;
    my $body = lc $Mess->GetBody();
    my $jid  = $Mess->GetFrom();

    # get account without ressource
    $jid =~ /(.+@.+\.\w+)\/.+/;
    $account = lc $1;

    INFO( "Event at: " . localtime(time) );
    INFO( "Message from: $account" );
    INFO( "Body: $body" );

    # command selection
    if ( $body eq 'list' ) {
        podlist();
    }
    elsif ( $body eq 'reglist' ) {
        reglist();
    }
    elsif ( $body =~ /^reg ([\w|\d|-]+)$/i ) {
        register($1);
    }
    elsif ( $body =~ /^unreg ([\*|\w|\d|-]+)$/i ) {
        unregister($1);
    }
    elsif ( $body =~ /^notify (on|off)$/i ) {
        showpadinfo($1);
    }
    elsif ( $body eq 'about' ) {
        about();
    }
    elsif ( $body eq '' ) {
        print "Empty Body\n";

        # do nothing...
        # workaround for empty message bodys
    }
    elsif ($body eq 'syn') {
        $msg = "SYN-ACK";
        $syn = 1;
        print "$account found the easteregg!\n";
    }
    elsif ($body eq 'ack' and $syn == 1) {
        $msg = "Easter egg connection established\nCongratulations!";
        $syn = 0;
    }
    elsif ($body eq 'fin') {
        $msg = "FIN-ACK";
        $fin = 1;
        print "$account found the easteregg!\n";
    }
    elsif ($body eq 'ack' and $fin == 1) {
        $msg = "Easter egg connection disconnected\nByeBye!";
        $fin = 0;
    }
    else {
        printhelp();
    }

    # send message back to client
    $con->MessageSend( to => $account, type => 'chat', body => $msg );
    $msg = '';
    return;
}

#showpad info
sub showpadinfo {

    my $servicehost = $cfg->param('server');

    $dbh->do(
        "INSERT OR IGNORE INTO subscribers
                VALUES('$account','$servicehost',0,0)
        "
    );

    $dbh->do(
        "INSERT OR IGNORE INTO padinfo
                VALUES('$account',0)
        "
    );

    my $infoverbal = shift;
    my $info       = 0;

    if ( $infoverbal eq "on" ) {
        $info = 1;
    }

    my $sth = $dbh->do(
        "UPDATE padinfo SET info=$info
                WHERE jid LIKE '$account'
        "
    );
    if ( $info == 1 ) {
        $msg = "Showpad notification activated";
    }
    else {
        $msg = "Showpad notification deactivated";
    }
}

# about
sub about {
    $msg =
"Shownotes Message Service\n=========================\n\nSource: https://github.com/shownotes/shownotes-message-service\n\nAuthor: Martin Stoffers\nEmail: Dr4k3\@shownot.es\nJabber: Dr4k3\@fastreboot.de\n\nContributers:\n\n Simon Waldherr\n Email:  Simon\@shownot.es\n Jabber: SimonWaldherr\@jabber.shownot.es\n\n Ingolf Gürges\n Jabber: ingolf\@fastreboot.de\n\n\nThis program is published under the terms of GPLv2 and comes with no warranty.\nhttp://www.gnu.org/licenses/gpl-2.0.txt";
}

# help
sub printhelp {
    $msg =
"list - Get a list of podcasts\n\nreg < podcast > - Subscribe to a podcast notification\n\nreglist - Get a list of all your subscribtions\n\nunreg < podcast | * > - Unsubscribe a podcast notification\n\nnotify < ON | OFF > - Get notifications about new showpads on http://pad.shownot.es\n\nabout - About the bot";
}

# list all podcasts
sub podlist {

    my $sth = $dbh->prepare(
        "SELECT slug FROM podcasts
                ORDER BY slug ASC
        "
    );
    $sth->execute();

    my $column;
    while ( $column = $sth->fetchrow_array() ) {
        $msg = $msg . "$column; ";
    }

    $sth->finish();
}

# lists all subscribed podcasts of a user
sub reglist {

    my $sth = $dbh->prepare(
        "SELECT slug FROM subscriptions
                WHERE jid LIKE '$account'
        "
    );
    $sth->execute();

    my $column;
    $msg = $msg . "You are subscribed to the following podcasts notifications:\n";
    while ( $column = $sth->fetchrow_array() ) {
        $msg = $msg . "  $column\n";
    }

    $sth->finish();
}

# unregister a podcast
sub unregister {
    my $podslug = shift;

    if ( $podslug eq '*' ) {
        $dbh->do(
            "DELETE FROM subscriptions
                    WHERE jid LIKE '$account'
            "
        );

        # set message
        $msg = "Unsubscribed from all podcast notifications";
        INFO("Unsubscribed $account from all podcast notifications");
    }
    else {
        $dbh->do(
            "DELETE FROM subscriptions
                    WHERE jid LIKE '$account'
                    AND slug LIKE '$podslug'
            "
        );

        # set message
        $msg = $podslug . " unsubscribed";
        INFO("$podslug unsubscribed for $account");
    }
}

# register a podcast
sub register {
    my $podslug     = shift;
    my $servicehost = $cfg->param('server');
    my $sth         = $dbh->prepare(
        "SELECT slug FROM podcasts
                WHERE slug LIKE '$podslug'
        "
    );
    $sth->execute();

    if ( defined $sth->fetchrow_array() ) {
        $sth->finish();

        $dbh->do(
            "INSERT OR IGNORE INTO subscribers
                    VALUES('$account','$servicehost',0,0)
            "
        );

        $dbh->do(
            "INSERT OR IGNORE INTO padinfo
                    VALUES('$account',0)
            "
        );

        my $timestamp = time;
        $dbh->do(
            "INSERT INTO subscriptions 
                    SELECT '$account','$podslug',$timestamp 
                    WHERE NOT EXISTS
                        ( SELECT jid,slug FROM subscriptions
                            WHERE jid LIKE '$account'
                            AND slug LIKE '$podslug'
                        )
            "
        );

        # set message
        $msg = $podslug . " registered to " . $account;
        INFO("$podslug registered for $account");

    }
    else {
        $msg = $podslug . " not in list";
        INFO("Register failed for $podslug");
        $sth->finish();
    }
}
