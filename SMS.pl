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

my $cfg = new Config::Simple('sms.config');

my $msg = "";
my $fileprefix = $cfg->param('directory');
my $account = '';
my $con = new Net::XMPP::Client();
my $reader;

$con->SetMessageCallBacks(chat=>\&message);
$con->SetCallBacks(onauth=>\&send_status);
$con->Execute(  hostname=>$cfg->param('server'),
                port=>$cfg->param('port'),
                username=>$cfg->param('username'),
                password=>$cfg->param('password'),
                resource=>$cfg->param('resource')
             );

sub send_status {
    print "\nAuthenticated\n";
    $con->PresenceSend(show => "available");
}

sub message {
    my ($sid,$Mess) = @_;
    my $body = $Mess->GetBody();
    my $jid = $Mess->GetFrom();
    
    $jid =~ /(\w+@\w+\.\w+)\/.+/;
    $account = $1;

    print "Nachricht von: ".$account."\n";
    print "       Inhalt: ".$body."\n";

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
    
    $con->MessageSend(to => $account, type =>'chat' ,body => $msg);
    $msg = '';
    return
}

sub error {
    $msg = "Not a valid command!\n\nSend \"help\" for a command list";
}

sub printhelp {
    $msg = "list - Get a list of podcasts\nreg <podcastname> - Register a podcast";
}

sub podlist {

    opendir DIR, $fileprefix or die $!;
    my @verzeichnisse = readdir(DIR);
    
    @verzeichnisse = sort(@verzeichnisse);

    foreach my $entry (@verzeichnisse) {
        
        $entry =~ m/(.+)\.xml/;
        
        #hack needs because of regex 
        if($1 ne $account) {
            $msg = $msg.$1.";  ";
        }
    }
    
    closedir DIR;
}

sub register {
    my $podslug = shift;
    
    if(-e "$fileprefix$podslug.xml"){
        
        #Subscriber gegenprüfen
        my $parser = XML::LibXML->new;
        my $doc = $parser->parse_file("$fileprefix$podslug.xml");

        my ($node) = $doc->findnodes('/xml/subscribers');

        my $new_element= $doc->createElement("subscriber");
        $new_element->appendText($account);

        $node->appendChild($new_element);

        open my $out, '>', "$fileprefix$podslug.xml";
        binmode $out; # as above
        $doc->toFH($out);
        
        $msg = $podslug." registered to ".$account;
    }
    else{
        $msg = $podslug." not in list";
    }
}
