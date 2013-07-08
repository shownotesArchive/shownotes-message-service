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

# create table if not exists
$dbh->do("CREATE TABLE IF NOT EXISTS Subscriber(Jid TEXT, Slug TEXT )");

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
    elsif($body =~ /^reg (.+)/i) {
        register($1);
    }
    else {
        printhelp();
    }
    
    # send message back to client
    $con->MessageSend(to => $account, type =>'chat' ,body => $msg);
    $msg = '';
    return
}

# error function
sub error {
    $msg = "Not a valid command!\n\nSend \"help\" for a command list";
}

# help
sub printhelp {
    $msg = "list - Get a list of podcasts\nreg <podcastname> - Register a podcast";
}

# list all podcasts
sub podlist {
    
    my $sth = $dbh->prepare( "SELECT Slug FROM Podcasts" );  
    $sth->execute();
          
    my $column;
    while ($column = $sth->fetchrow_array()) {
        $msg =  $msg."$column; ";
    }

    $sth->finish();
}

# register a podcast
sub register {
    my $podslug = shift;

    my $sth = $dbh->prepare( "SELECT Slug FROM Podcasts WHERE Slug = \'$podslug\'" );  
    $sth->execute();
          
    if(defined $sth->fetchrow_array()) {
        $sth->finish();
        
        my $sth = $dbh->prepare( "SELECT Slug FROM Subscriber
                                  WHERE Jid = \'$account\'
                                  AND Slug = \'$podslug\'");  
        $sth->execute();
        if(defined $sth->fetchrow_array()) {
            $msg = $podslug." already registered";
            print "        ".$podslug." was already to $account before\n";
        }
        else{
            #subscribe account
            $dbh->do("INSERT INTO Subscriber VALUES('$account','$podslug')");
            
            # set message
            $msg = $podslug." registered to ".$account;
            print "        ".$podslug." registered for $account\n";
        }
        $sth->finish();
    }
    else{
        $msg = $podslug." not in list";
        print "        Register failed for $podslug\n";
        $sth->finish();
    }


}
