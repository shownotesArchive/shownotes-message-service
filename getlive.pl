#!/usr/bin/perl -s
#
## Scanning new Live-Podcasts

use strict;
use warnings;
use utf8;

use POSIX;
use Data::Dumper;
use XML::LibXML::Reader;
use XML::Writer;
use IO::File;

use Net::XMPP;
use LWP::Simple;
use JSON;

my $fileprefix = 'podcasts/';
my $json = JSON->new->allow_nonref;

my $rawdata = get("http://hoersuppe.de/api/?action=getLive&dateStart=".getdate()."&dateEnd=".getdate());
my $live = $json->decode( $rawdata );

my $my = $live->{"data"};

foreach my $livepod (@$my){
    my $podslug = $livepod->{"podcast"};
   
    if($podslug ne '' and -e "$fileprefix$podslug.xml"){
 
        my $live = $livepod->{"livedate"};
        $live =~ m/((\d+)-(\d+)-(\d+)) ((\d\d):(\d\d):\d\d)/;
        my $livedate = $1;
        my $livetime = $5;
        my $livehour = $6;

        if ($livehour == (gethour()+1)) {    

            print "Schicke Nachricht\n";
            my $msg = $podslug." läuft am ".$livedate." um ".$livetime." Uhr.";

            my $reader = XML::LibXML::Reader->new(location => "$fileprefix$podslug.xml");

            while ($reader->read)
            {
                my $account = processNode($reader);
                if($account ne ''){
                    sendnotice($account,$msg);
                }
            }
        }
        elsif ($livehour < (gethour()+1)) {
            print $podslug." nicht relevant - ".$livehour." < ".(gethour()+1)."\n";
        }
        elsif  ($livehour > (gethour()+1)) {
            print $podslug." nicht relevant - ".$livehour." > ".(gethour()+1)."\n";
        }
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
            if ($reader->value =~ m/\w+@\w+\..+/) {
                $account = $reader->value;
            }
        }
    }
    $account;
}

sub sendnotice {
    my ($account,$msg) = @_;
    my $con = new Net::XMPP::Client();
    my $status = $con->Connect(hostname => 'fastreboot.de', connectiontype => 'tcpip', tls => 0);
    die('ERROR: XMPP connection failed') if ! defined($status);

    my @result = $con->AuthSend(hostname => 'fastreboot.de', username => 'sms',password => 'smsinfoclient', resource => 'info');
    die('ERROR: XMPP authentication failed') if $result[0] ne 'ok';

    die('ERROR: XMPP message failed') if ($con->MessageSend(to => $account, body => $msg) != 0);
    print "Send to $account\n";

}

sub getdate {
    my $Xdatum = strftime "%Y-%m-%d", localtime;
}

sub gethour {
    my $Xdatum = strftime "%H", localtime;
}

