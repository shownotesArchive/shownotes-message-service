#!/usr/bin/perl -s
#
## Hoersuppe.de scanner 

use strict;
use warnings;
use utf8;

use Config::Simple;
use File::Basename;

use DBI;

use LWP::Simple;
use JSON;

# make a new config reader object
my $currentpath = dirname(__FILE__);
my $cfg = new Config::Simple("$currentpath/sms.config");
my $programmpath = $cfg->param('directory');

# connect to database
my $dbh = DBI->connect("dbi:SQLite:dbname=$programmpath/data.db",
                       "",
                       "",
                       {RaiseError => 1}, #Exceptions instead of error
) or die $DBI::errstr;

# create table if not exists
$dbh->do("CREATE TABLE IF NOT EXISTS podcasts(
                    slug TEXT PRIMARY KEY,
                    title TEXT
        )");

# make a JSON parser object
my $json = JSON->new->allow_nonref;

# get JSON via LWP and decode it to hash
my $rawdata = get("http://hoersuppe.de/api/?action=getPodcasts");
my $podcast_data = $json->decode( $rawdata );

my $podcasts = $podcast_data->{"data"};

# insert Podcasts in DB
foreach my $podcast (@$podcasts){
    my $podtitle = $podcast->{"title"};
    my $podslug = $podcast->{"slug"};

    if(defined $podslug){
        my $sth = $dbh->prepare("SELECT slug FROM podcasts WHERE slug LIKE \'$podslug\'");
        $sth->execute();
              
        if(defined $sth->fetchrow_array()){
            print "\t- Podcast ".$podslug." is in database\n";
        }
        else{
            my $rawdata_info = get("http://hoersuppe.de/api/?action=getPodcastData&podcast=$podslug");
            my $podcast_info = $json->decode( $rawdata_info );
            
            if($podcast_info->{"data"}->{"obsolete"} ne "1"){
                $dbh->do("INSERT INTO podcasts VALUES('$podslug','$podtitle')");
                print "\t+ Podcast ".$podslug." created\n";
            }
        }
        $sth->finish();
    } 
}

$dbh->disconnect();
