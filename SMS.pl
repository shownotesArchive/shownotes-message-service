#!/usr/bin/perl -s
#
## Shownotes Message Service 

use strict;
use warnings;
use utf8;

use Data::Dumper;
use Config::Simple;

use DBI;

use Net::XMPP;
use LWP::Simple;
use JSON;

# make a new config config object
my $cfg = new Config::Simple('sms.config');

# some global variables
my $msg = "";
my $programpath = $cfg->param('directory');
my $account = '';

# connect to database
my $dbh = DBI->connect("dbi:SQLite:dbname=$programpath/data.db",
                       "",
                       "",
                       {RaiseError => 1}, #Exceptions instead of error
) or die $DBI::errstr;

$dbh->do("PRAGMA foreign_keys = ON");

# create Subscription table if not exists
$dbh->do("CREATE TABLE IF NOT EXISTS subscriptions(
                jid TEXT NOT NULL,
                slug TEXT NOT NULL,
                timestamp INT NOT NULL,
                UNIQUE (jid,slug)
        )");

# create Subscribers table if not exists
$dbh->do("CREATE TABLE IF NOT EXISTS subscribers(
                jid TEXT NOT NULL,
                servicehost TEXT NOT NULL,
                token TEXT DEFAULT 0,
                challenge TEXT DEFAULT 0,
                info INT NOT NULL DEFAULT 0,
                UNIQUE (jid,servicehost)
        )");

# make a jabber client object
my $con = new Net::XMPP::Client();

# set the callback functions
$con->SetMessageCallBacks(chat=>\&message);
$con->SetCallBacks(onauth=>\&send_status);
$con->SetPresenceCallBacks(type=>undef);

# execute jabber client
$con->Execute(  hostname=>$cfg->param('server'),
                port=>$cfg->param('port'),
                username=>$cfg->param('username'),
                password=>$cfg->param('password'),
                resource=>$cfg->param('botresource')
             );

# status update callback
sub send_status {
    print "\tAuthenticated\n\n";
    $con->PresenceSend(show => "chat");
}

# callback for message handle
sub message {
    
    # get informations about the client, who is connected
    my ($sid,$Mess) = @_;
    my $body = lc $Mess->GetBody();
    my $jid = $Mess->GetFrom();
   
    # get account without ressource
    $jid =~ /(.+@.+\.\w+)\/.+/;
    $account = lc $1;
    
    print "\n";
    print "    Event at: ".localtime(time).":\n";
    print "Message from: ".$account."\n";
    print "        Body: ".$body."\n";

    # command selection
    if($body eq 'list') {
        podlist();
    }
    elsif($body eq 'reglist') {
        reglist();
    }
    elsif($body =~ /^reg ([\w|\d|-]+)/i) {
        register($1);
    }
    elsif($body =~ /^unreg ([\*|\w|\d|-]+)/i) {
        unregister($1);
    }
    elsif($body eq 'about'){
        about();
    }
    elsif($body eq ''){
        print "Empty Body\n";
        # do nothing... 
        # workaround for empty message bodys
    }
    else {
        printhelp();
    }

    # send message back to client
    $con->MessageSend(to => $account, type =>'chat' ,body => $msg);
    $msg = '';
    return
}

# about
sub about {
    $msg = "Shownotes Message Service\n=========================\n\nAuthor: Martin Stoffers\nEmail:  Dr4k3\@shownot.es\nSource: https://github.com/shownotes/shownotes-message-service\n\nContributers: SimonWaldherr\n\nThis program is published under the terms of GPLv2 and comes with no warranty.\nhttp://www.gnu.org/licenses/gpl-2.0.txt";
}

# help
sub printhelp {
    $msg = "list - Get a list of podcasts\nreg <podcast> - Subscribe to a podcast notification\nreglist - Get a list of all your subscribtions\nunreg <podcast | *> - Unsubscribe a podcast notification\nabout - About the bot";
}

# list all podcasts
sub podlist {
    
    my $sth = $dbh->prepare("SELECT slug FROM podcasts
                                ORDER BY slug ASC
                           ");
    $sth->execute();

    my $column;
    while ($column = $sth->fetchrow_array()) {
        $msg = $msg."$column; ";
    }

    $sth->finish();
}

# lists all subscribed podcasts of a user
sub reglist {
    
    my $sth = $dbh->prepare("SELECT slug FROM subscriptions
                                WHERE jid LIKE '$account'
                            ");
    $sth->execute();
          
    my $column;
    $msg = $msg."You are subscribed to the following podcasts notifications:\n";
    while ($column = $sth->fetchrow_array()) {
        $msg = $msg."  $column\n";
    }

    $sth->finish();
}

# unregister a podcast
sub unregister {
    my $podslug = shift;
    
    if ($podslug eq '*') {
        $dbh->do("DELETE FROM subscriptions
                    WHERE jid LIKE '$account'");
            
        # set message
        $msg = "Unsubscribed from all podcast notifications";
        print "        ".$account." all podcast notifications\n";
    }
    else {
        $dbh->do("DELETE FROM subscriptions
                    WHERE jid LIKE '$account'
                    AND slug LIKE '$podslug'
                 ");
            
        # set message
        $msg = $podslug." unsubscribed";
        print "        ".$podslug." unsubscribed for $account\n";
    }
}

# register a podcast
sub register {
    my $podslug = shift;
    my $servicehost = $cfg->param('server');
    my $sth = $dbh->prepare("SELECT slug FROM podcasts
                                WHERE slug LIKE '$podslug'
                            ");  
    $sth->execute();
          
    if(defined $sth->fetchrow_array()) {
        $sth->finish();

        $dbh->do("INSERT OR IGNORE INTO subscribers
                    VALUES('$account','$servicehost',0,0,0)
                ");

        my $timestamp = time;
        $dbh->do("INSERT INTO subscriptions 
                    SELECT '$account','$podslug',$timestamp 
                    WHERE NOT EXISTS (
                        ( SELECT jid,slug FROM subscriptions
                            WHERE jid LIKE '$account'
                            AND slug LIKE '$podslug'
                        )
                ");
            
        # set message
        $msg = $podslug." registered to ".$account;
        print "        ".$podslug." registered for $account\n";
        
        }
        else{
            $msg = $podslug." not in list";
            print "        Register failed for $podslug\n";
            $sth->finish();
        }
}
