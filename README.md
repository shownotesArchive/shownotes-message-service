# Shownotes Message Service

A simple jabber notification service for live podcasts. Based upon the data of [hoersuppe.de](http://hoersuppe.de "hoersuppe.de") from [@eazyliving](https://github.com/eazyliving "@eazyliving").
<br>
<br>
**Give it a try** but beware the service is under heavy development. :) 

Send **help** with your favorite Jabber/XMPP client to:<br>
<pre>
sms@fastreboot.de
</pre>

# Setup

## Basic requirements for all scripts
* perl 5.14
* sqlite3

## Perl Packages

* Config:Simple
* POSIX
* File:Basename
* DBI
* Net::XMPP
* LWP::Simple
* JSON

## Deeper introductions

[doc/jabber-service-setup.md](doc/jabber-service-setup.md "Here you will find the basic setup for the notification service.")

[doc/rest-client-setup.md](doc/rest-client-setup.md "Here you will find the additional setup for the REST client.")

# Licence

**This programm is published under the terms of GPLv2 and comes with no warranty.**
**Use it on your own risk.**
