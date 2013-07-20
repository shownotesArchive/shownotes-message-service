#!/usr/bin/perl -s
#
## Scanning new Live-Podcasts

use strict;
use warnings;
use utf8;

use POSIX;
use Data::Dumper;
use Config::Simple;
use File::Basename;

use DBI;

use Net::XMPP;
use LWP::Simple;
use JSON;

# make a new config reader object
my $programpath = dirname(__FILE__);
my $cfg = new Config::Simple("$programpath/sms.config");
my $datapath = $cfg->param('directory');

# connect to database
my $dbh = DBI->connect("dbi:SQLite:dbname=$programpath/data.db",
                       "",
                       "",
                       {RaiseError => 1}, #Exceptions instead of error
) or die $DBI::errstr;

# make a JSON parser object
my $json = JSON->new->allow_nonref;

# get JSON via LWP and decode it to hash
my $rawdata = get("http://hoersuppe.de/api/?action=getLive&dateStart=".getdate()."&dateEnd=".getdate());
my $live = $json->decode( $rawdata );

# get slugs from data
my $my = $live->{"data"};
foreach my $livepod (@$my){
    my $podslug = $livepod->{"podcast"};
    
    my $sth = $dbh->prepare( "SELECT Slug FROM Podcasts WHERE Slug = \'$podslug\'" );
    $sth->execute();
          
    if(defined $sth->fetchrow_array()) {
        $sth->finish();

        my $live = $livepod->{"livedate"};
        $live =~ m/((\d+)-(\d+)-(\d+)) ((\d\d):(\d\d):\d\d)/;
        my $livedate = $1;
        my $livetime = $5;
        my $livehour = $6;

        # if podcast is in range search for subsribers
        if ($livehour == (gethour()+1)) {   

            #print "Search subscribers for ".$podslug."\n";
            my $sth = $dbh->prepare( "SELECT Jid FROM Subscriptions WHERE Slug = \'$podslug\'");  
            $sth->execute();

            my $account;
            while ($account = $sth->fetchrow_array()) {
                    
               my $msg = $podslug." starts at ".$livetime;
               sendnotice($account,$podslug,$msg);
            }
            $sth->finish();
        }

    }
}    

# send notification to subscriber
sub sendnotice {
    my ($account,$podslug,$msg) = @_;

    # Make a new Jabber object an connect
    my $con = new Net::XMPP::Client();
    my $status = $con->Connect(hostname => $cfg->param('server'), connectiontype => 'tcpip', tls => 0);
    die('ERROR: XMPP connection failed') if ! defined($status);

    # authenticate
    my @result = $con->AuthSend(hostname =>$cfg->param('server'), username =>$cfg->param('username'),password =>$cfg->param('password'), resource => $cfg->param('inforesource'));
    die('ERROR: XMPP authentication failed') if $result[0] ne 'ok';

    # send a message
    # type = "headline" for penetrant notfication on client-side
    die('ERROR: XMPP message failed') if ($con->MessageSend(to => $account, type =>'chat', body => $msg) != 0);
    print "Send notification about $podslug to $account\n";

}

# get formated date
sub getdate {
    my $Xdatum = strftime "%Y-%m-%d", localtime;
}

sub gethour {
    my $Xdatum = strftime "%H", localtime;
}

