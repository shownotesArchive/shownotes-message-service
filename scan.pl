#!/usr/bin/perl -s
#
## Hoersuppe.de scanner 

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

my $json = JSON->new->allow_nonref;
my $rawdata = get("http://hoersuppe.de/api/?action=getPodcasts");
my $podcasts = $json->decode( $rawdata );

my $my = $podcasts->{"data"};

foreach my $podcast (@$my){
    my $podtitle = $podcast->{"title"};
    my $podslug = $podcast->{"slug"};
    
    if (!(-e "$fileprefix$podslug.xml")) {
        
        print "Podcast ".$podslug." wird angelegt\n"; 
        
        my $output = IO::File->new(">$fileprefix$podslug.xml");
        my $writer = XML::Writer->new(OUTPUT => $output);
        $writer->xmlDecl("UTF-8","yes");
        $writer->doctype("xml");

        $writer->startTag("xml","podcast" => $podslug);
        $writer->startTag("title");
        $writer->characters($podtitle);
        $writer->endTag("title");
        $writer->startTag("subscribers");
        $writer->endTag("subscribers");
        $writer->endTag("xml");
        
        $writer->end();
        $output->close();
    }
    #else{
    #    print $podslug." übersprungen\n"; 
    #}

}




