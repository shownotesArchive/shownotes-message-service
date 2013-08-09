# Shownotes Message Service

A simple jabber notification service for live podcasts. Based upon the data of [hoersuppe.de](http://hoersuppe.de "hoersuppe.de") from [@eazyliving](https://github.com/eazyliving "@eazyliving").
<br>
<br>
**Give it a try** but beware the service is under heavy development. :) 

<pre>
bot@jabber.shownot.es
</pre>

# Available commands
```
list - Get a list of podcasts you could subscribe
reg <podcast> - Subscribe to a podcast notification
reglist - Get a list of all your subscription
unreg <podcast | all> - Unsubscribe a podcast notifcation
```

# Setup

## Basic requirements for all scripts
* perl 5.14
* sqlite3

## Perl modules

* Config::Simple
* POSIX
* File::Basename
* DBI
* Net::XMPP
* LWP::Simple
* JSON

## Further introductions

[Basic setup for the Shownotes Message Service.](doc/jabber-service-setup.md "Basic setup for the Shownotes Message Service.")

[Additional setup for the REST client.](doc/rest-client-setup.md "Additional setup for the REST client.")

## Licence

This program is published under the terms of [GPLv2](LICENSE "GPLv2") and comes with no warranty.
