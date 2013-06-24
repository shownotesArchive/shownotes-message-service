#!/usr/bin/perl -s
#
## Scanning new Live-Podcasts

use strict;
use warnings;
use utf8;

use Data::Dumper;
use XML::LibXML::Reader;
use XML::Writer;
use IO::File;

use Net::XMPP;
use LWP::Simple;
use JSON;

my $fileprefix = 'podcasts/';

sub getdate {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$ydat,$isdst)=localtime();
    my $jahr=$year;
    my $monat=$mon+1;
    my $tag=$mday;

    $jahr=$year +1900;

    if (length($monat) == 1)
    {
        $monat="0$monat";
    }   
    if(length($tag) == 1)
    {
       $tag="0$tag";
    }

    my $Xdatum=$jahr."-".$monat."-".$tag;
}

sub gettime {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$ydat,$isdst)=localtime();
    
    if(length($hour) == 1)
    {
       $hour="0$hour";
    }
    if(length($min) == 1)
    {
       $min="0$min";
    }
    if(length($sec) == 1)
    {
       $sec="0$sec";
    }

    my $Xzeit=$hour.":".$min.":".$sec;
}

sub gethour {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$ydat,$isdst)=localtime();
    
    if(length($hour) == 1)
    {
       $hour="0$hour";
    }
    $hour;
}
sub getmin {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$ydat,$isdst)=localtime();
    
    if(length($min) == 1)
    {
       $min="0$min";
    }
    $min;
}

sub sendnotice {
    my $podslug = shift;
    print $podslug."\n";

}

my $json = JSON->new->allow_nonref;
my $rawdata = get("http://hoersuppe.de/api/?action=getLive&dateStart=".getdate()."&dateEnd=".getdate());
my $live = $json->decode( $rawdata );

my $my = $live->{"data"};

foreach my $livepod (@$my){
    my $live = $livepod->{"livedate"};
    
    $live =~ m/(\d+-\d+-\d+) ((\d\d):\d\d:\d\d)/;
    my $date = $1;
    my $time = $2;
    my $hour = $3;
    
    my $podslug = $livepod->{"podcast"};
   
     if($podslug ne '') {
        if ($hour == gethour()+1) {

            print "Schicke Nachricht\n";
            #print $podslug." läuft am ".$date." um ".$time." Uhr. \n";
            sendnotice($podslug);
        }
        else {
            print $podslug." nicht relevant - ".$hour." > ".(gethour()+1)."\n";
        }
     }

}


