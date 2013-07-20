# Basic setup - Shownotes Message Service 

## Special requirements
* cron or a similar service
* A jabber account for your bot - could be useful ;)

## Step 1 - Clone it
Clone the repository into your preferred directory

```
git clone git@github.com:Drake81/shownotes-message-service.git
```

## Step 2 - Setup for the timed scripts

Edit your crontab

```
crontab -e
```

It should look like the following example

```
# m h dom mon dow   command
0 * * * * /path/to/your/script/getlive.pl
0 0 * * * /path/to/your/script/scan.pl
```

* scan.pl will scan every 24 hours for new podcasts which could be subscribed
* getlive.pl will scan every hour for new live events and send notifications to each subscriber if necessary.

## Step 3 - Start the jabber service

Fire up the start.sh.

```
./start.sh
```

This creates a new sms.config file, if not exists. Edit it to your needs.
Afterwards the script initiates the database file and starts a scan with scan.pl for new podcasts.
After it the bot script will be started.
Your service should be available, now.
