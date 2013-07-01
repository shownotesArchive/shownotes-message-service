#!/usr/bin/perl -s
#
## Scanning new Live-Podcasts

use strict;
use warnings;
use utf8;

use POSIX;
use Data::Dumper;
use Config::Simple;

use XML::LibXML::Reader;
use XML::Writer;
use IO::File;

use Net::XMPP;
use LWP::Simple;
use JSON;

# make a new config reader object
my $cfg = new Config::Simple('sms.config');
my $fileprefix = $cfg->param('directory');

# make a JSON parser object
my $json = JSON->new->allow_nonref;

# get JSON via LWP and decode it to hash
my $rawdata = get("http://hoersuppe.de/api/?action=getLive&dateStart=".getdate()."&dateEnd=".getdate());
my $live = $json->decode( $rawdata );

# get slugs from data
my $my = $live->{"data"};
foreach my $livepod (@$my){
    my $podslug = $livepod->{"podcast"};
   
    # if slug exists as xml in data directory; go on
    if($podslug ne '' and -e "$fileprefix$podslug.xml"){
 
        my $live = $livepod->{"livedate"};
        $live =~ m/((\d+)-(\d+)-(\d+)) ((\d\d):(\d\d):\d\d)/;
        my $livedate = $1;
        my $livetime = $5;
        my $livehour = $6;

        # if podcast is in range search for subsribers in xml
        if ($livehour == (gethour()+1)) {    

            #print "Search subscribers for ".$podslug."\n";
            my $msg = $podslug." starts at ".$livetime;

            my $reader = XML::LibXML::Reader->new(location => "$fileprefix$podslug.xml");

            while ($reader->read)
            {
                # send a message to each subscriber
                my $account = processNode($reader);
                if($account ne ''){
                    print "Send to: ".$account."\n";
                    sendnotice($account,$msg);
                }
            }
        }
        #elsif ($livehour < (gethour()+1)) {
        #    print $podslug." not in  - ".$livehour." < ".(gethour()+1)."\n";
        #}
        #elsif  ($livehour > (gethour()+1)) {
        #    print $podslug." nicht relevant - ".$livehour." > ".(gethour()+1)."\n";
        #}
    }
}

#sub for xml-reader
sub processNode {
    my $reader = shift;
    my $account = '';
    if($reader->name eq "#text")
    {
        if($reader->hasValue)
        {
            if ($reader->value =~ m/\w+@\w+\.\w+/) {
                $account = $reader->value;
            }
        }
    }
    $account;
}

# send notification to subscriber
sub sendnotice {
    my ($account,$msg) = @_;

    # Make a new Jabber object an connect
    my $con = new Net::XMPP::Client();
    my $status = $con->Connect(hostname => $cfg->param('server'), connectiontype => 'tcpip', tls => 0);
    die('ERROR: XMPP connection failed') if ! defined($status);

    # authenticate
    my @result = $con->AuthSend(hostname =>$cfg->param('server'), username =>$cfg->param('username'),password =>$cfg->param('password'), resource => $cfg->param('inforesource'));
    die('ERROR: XMPP authentication failed') if $result[0] ne 'ok';

    # send a message
    die('ERROR: XMPP message failed') if ($con->MessageSend(to => $account, type =>'headline', body => $msg) != 0);
    print "Send to $account\n";

}

# get formated date
sub getdate {
    my $Xdatum = strftime "%Y-%m-%d", localtime;
}

sub gethour {
    my $Xdatum = strftime "%H", localtime;
}

