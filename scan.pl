#!/usr/bin/perl -s
#
## Hoersuppe.de scanner 

use strict;
use warnings;
use utf8;

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
my $rawdata = get("http://hoersuppe.de/api/?action=getPodcasts");
my $podcasts = $json->decode( $rawdata );

my $my = $podcasts->{"data"};

# write a new xml for each slug if not exist
foreach my $podcast (@$my){
    my $podtitle = $podcast->{"title"};
    my $podslug = $podcast->{"slug"};
    
    if (!(-e "$fileprefix$podslug.xml")) {
        
        
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
        
        print "Podcast ".$podslug." created\n"; 
    }

}




