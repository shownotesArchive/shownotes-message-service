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
                Jid TEXT NOT NULL REFERENCES Subscribers(Jid) ON DELETE CASCADE, 
                Slug TEXT NOT NULL REFERENCES Podcasts(Slug) ON DELETE CASCADE, 
                Timestamp INT NOT NULL, 
                Service INT NOT NULL
        )");

# create Subscription table if not exists
$dbh->do("CREATE TABLE IF NOT EXISTS Subscribers(
                Jid TEXT NOT NULL, 
                pad TEXT,
                info INT NOT NULL DEFAULT 0,
                PRIMARY KEY(Jid)
        )");

$dbh->do("CREATE TRIGGER IF NOT EXISTS update_subscribers AFTER DELETE ON subscriptions
            BEGIN
                DELETE FROM subscribers WHERE jid NOT IN (SELECT DISTINCT jid FROM subscriptions);
            END
         ");

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
    my $body = $Mess->GetBody();
    my $jid = $Mess->GetFrom();
   
    # get account without ressource
    $jid =~ /(.+@.+\.\w+)\/.+/;
    $account = $1;
    
    print "Message from: ".$account."\n";
    print "        Body: ".$body."\n";

    # command selection
    if($body eq 'list') {
        podlist();
    }
    elsif($body eq 'reglist') {
        reglist();
    }
    elsif($body =~ /^reg (.+)/i) {
        register($1);
    }
    elsif($body =~ /^unreg (.+)/i) {
        unregister($1);
    }
    else {
        printhelp();
    }
    
    # send message back to client
    $con->MessageSend(to => $account, type =>'chat' ,body => $msg);
    $msg = '';
    return
}

# help
sub printhelp {
    $msg = "list - Get a list of podcasts\nreg <podcast> - Subscribe to a podcast notification\nreglist - Get a list of all your subscribtions\nunreg <podcast | all> - Unsubscribe a podcast notification";
}

# list all podcasts
sub podlist {
    
    my $sth = $dbh->prepare("SELECT Slug FROM Podcasts");
    $sth->execute();
          
    my $column;
    while ($column = $sth->fetchrow_array()) {
        $msg =  $msg."$column; ";
    }

    $sth->finish();
}

# lists all subscribed podcasts of a user
sub reglist {
    
    my $sth = $dbh->prepare("SELECT Slug FROM Subscriptions WHERE Jid = \'$account\'");
    $sth->execute();
          
    my $column;
    $msg = $msg."You are subscribed to the following podcasts notifications:\n";
    while ($column = $sth->fetchrow_array()) {
        $msg =  $msg."  $column\n";
    }

    $sth->finish();
}

# unregister a podcast
sub unregister {
    my $podslug = shift;
    
    if ($podslug eq 'all') {
        $dbh->do("DELETE FROM Subscribers WHERE Jid = \'$account\'");
            
        # set message
        $msg = "Unsubscribed from all podcast notifications";
        print "        ".$account." all podcast notifiactions\n";
    }
    else {
        $dbh->do("DELETE FROM Subscriptions WHERE Jid = \'$account\' AND Slug = \'$podslug\'");
            
        # set message
        $msg = $podslug." unsubscribed";
        print "        ".$podslug." unsubscribed for $account\n";
    }
}

# register a podcast
sub register {
    my $podslug = shift;

    my $sth = $dbh->prepare("SELECT Slug FROM Podcasts WHERE Slug = \'$podslug\'");  
    $sth->execute();
          
    if(defined $sth->fetchrow_array()) {
        $sth->finish();

        $dbh->do("INSERT OR IGNORE INTO Subscribers VALUES('$account',NULL,0)");

        my $timestamp = time;
        #$dbh->do("INSERT OR IGNORE INTO Subscriptions VALUES('$account','$podslug',$timestamp,0)");
        $dbh->do("INSERT INTO Subscriptions 
                    SELECT '$account','$podslug',$timestamp,0 
                    WHERE NOT EXISTS (
                        SELECT jid,slug 
                        FROM subscriptions 
                        WHERE jid like '$account'
                        AND slug like '$podslug'
                    )
                    AND '$podslug' IN (
                        SELECT slug
                        FROM podcasts
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
