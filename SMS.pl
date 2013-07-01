#!/usr/bin/perl -s
#
## Shownotes Message Service 

use strict;
use warnings;
use utf8;

use Data::Dumper;
use Config::Simple;

use XML::Simple;
use IO::File;
use XML::LibXML;

use Net::XMPP;
use LWP::Simple;
use JSON;

# make a new config reader object
my $cfg = new Config::Simple('sms.config');


# some global variables
my $msg = "";
my $fileprefix = $cfg->param('directory');
my $account = '';
my $reader;

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
    if($body eq 'help') {
        printhelp();
    }
    elsif($body eq 'list') {
        podlist();
    }
    elsif($body =~ /^reg (.+)/i) {
        register($1);
    }
    else {
        error();
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

    # open data directory and concatenate them to the message
    opendir DIR, $fileprefix or die $!;
    my @directories = readdir(DIR);
    
    @directories = sort(@directories);

    foreach my $entry (@directories) {
        
        $entry =~ m/(.+)\.xml/;
        
        #hack needs because of regex 
        if($1 ne $account) {
            $msg = $msg.$1.";  ";
        }
    }
    
    closedir DIR;
}

# register a podcast
sub register {
    my $podslug = shift;
    
    # write subscriber to xml if slug is available as xml
    if(-e "$fileprefix$podslug.xml"){

        # open xml    
        my $parser = XML::LibXML->new;
        my $doc = $parser->parse_file("$fileprefix$podslug.xml");

        my ($node) = $doc->findnodes('/xml/subscribers');

        # add subscriber as new element
        my $new_element= $doc->createElement("subscriber");
        $new_element->appendText($account);

        $node->appendChild($new_element);
        
        #write file
        open my $out, '>', "$fileprefix$podslug.xml";
        binmode $out; # as above
        $doc->toFH($out);
        
        # set message
        $msg = $podslug." registered to ".$account;
    }
    else{
        $msg = $podslug." not in list";
    }
}
