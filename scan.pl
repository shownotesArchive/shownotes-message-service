#!/usr/bin/perl -s
#
## Hoersuppe.de scanner 

use strict;
use warnings;
use utf8;

use Config::Simple;

use DBI;

#use IO::File;

use LWP::Simple;
use JSON;

# make a new config reader object
my $cfg = new Config::Simple('sms.config');
my $fileprefix = $cfg->param('directory');

# connect to database
my $dbh = DBI->connect("dbi:SQLite:dbname=$fileprefix/data.db",
                       "",
                       "",
                       {RaiseError => 1}, #Exceptions instead of error
) or die $DBI::errstr;

# create table if not exists
$dbh->do("CREATE TABLE IF NOT EXISTS Podcasts(Slug TEXT UNIQUE, Title TEXT)");

# make a JSON parser object
my $json = JSON->new->allow_nonref;

# get JSON via LWP and decode it to hash
my $rawdata = get("http://hoersuppe.de/api/?action=getPodcasts");
my $podcasts = $json->decode( $rawdata );

my $my = $podcasts->{"data"};

# insert Podcasts in DB
foreach my $podcast (@$my){
    my $podtitle = $podcast->{"title"};
    my $podslug = $podcast->{"slug"};
    
    my $sth = $dbh->prepare( "SELECT Slug FROM Podcasts WHERE Slug = \'$podslug\'" );  
    $sth->execute();
    
    if(defined $sth->fetchrow_array()) {
        $sth->finish();
        
        print "Podcast ".$podslug." is in list\n";    
        
    }
    else {
        $sth->finish();
        
        $dbh->do("INSERT INTO Podcasts VALUES('$podslug','$podtitle')");

        print "\t--> Podcast ".$podslug." created\n";    
    }

}

$dbh->disconnect();
