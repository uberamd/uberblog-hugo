+++
title = "installing sentry on ubuntu 14.04"
description = "Simple walkthrough describing the installation process of Sentry on Ubuntu 14.04"
author = "Steve Morrissey"
tags = [
  "tutorial",
  "linux",
  "ubuntu"
]
date = "2016-11-19T12:55:25-06:00"

+++

# Intro

So you want to deploy Sentry in your local environment, eh? Assuming you already know what Sentry does, I'll just give you the tagline from their website: Sentry provides real-time crash reporting for your web apps, mobile apps, and games. That's a pretty fantastic summary. What I use it for is gathering, grouping, and alerting on Ruby on Rails application issues. It wraps errors up in to a nice, easy to digest package that you can work through, resolve, and get trend analysis on. It works much better than parsing log files and best of all, it's free!

This guide will walk you through the setup process on a fairly clean Ubuntu 14.04 server. You should be able to copy/paste MOST of the below commands and end up with a working install.

# Lets get started!

Add an updated PPA that contains version 2.8.9 or newer, then update apt to grab the latest package sources: 

```
sudo add-apt-repository ppa:chris-lea/redis-server
sudo apt-get update
```

Install the required software and dependencies:

```
sudo apt-get install -y redis-server redis-tools python-setuptools python-pip python-dev libxslt1-dev libxml2-dev libz-dev libffi-dev libssl-dev libpq-dev libyaml-dev postgresql nginx-full supervisor
```

Install Virtualenv using pip:

```
sudo pip install -U virtualenv
```

Create a user to run Sentry as (give it a password, you can leave the rest of the questions empty):

```
sudo adduser sentry
```

Create a postgres user matching the newly created sentry user:

```
sudo su - postgres
psql template1
create user sentry with password 'somePasswordHere';
create database sentrydb with owner sentry;
\q
exit
```

Switch to the newly created user:

```
sudo su - sentry
```

Pick a location for the environment and create it:

```
virtualenv ~/sentry_app/
```

Source the environment:

```
source ~/sentry_app/bin/activate
```

Begin the Sentry installation:

```
pip install -U sentry
```

Initialize the sentry config files, this will create a config directory of ~/.sentry:

```
sentry init
```

Modify the sentry.conf.py file with the Postgresql information created above:

```
DATABASES = {
    'default': {
        'ENGINE': 'sentry.db.postgres',
        'NAME': 'sentrydb',
        'USER': 'sentry',
        'PASSWORD': 'somePasswordHere',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

Add redis connection information to the .sentry/config.yml file:

```
redis.clusters:
  default:
    hosts:
      0:
        host: 127.0.0.1
        port: 6379
```

Run the database migration scripts. At the end of this process it'll ask you to create a user, do so and make it a superuser:

```
sentry upgrade
```

Exit out of the Sentry user and create a startup script for supervisord. Supervisord will ensure all the processes needed for Sentry remain running:

```
exit
sudo vim /etc/supervisor/conf.d/sentry.conf
```

Paste the following into the sentry.conf supervisor file:

```
[program:sentry-web]
directory=/home/sentry/sentry_app/
environment=SENTRY_CONF="/home/sentry/.sentry"
command=/home/sentry/sentry_app/bin/sentry start
autostart=true
autorestart=true
redirect_stderr=true
user=sentry
stdout_logfile=syslog
stderr_logfile=syslog

[program:sentry-worker]
directory=/home/sentry/sentry_app/
environment=SENTRY_CONF="/home/sentry/.sentry"
command=/home/sentry/sentry_app/bin/sentry celery worker
autostart=true
autorestart=true
redirect_stderr=true
user=sentry
stdout_logfile=syslog
stderr_logfile=syslog

[program:sentry-cron]
directory=/home/sentry/sentry_app/
environment=SENTRY_CONF="/home/sentry/.sentry"
command=/home/sentry/sentry_app/bin/sentry celery beat
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=syslog
stderr_logfile=syslog
```

Save, exit, and tell supervisor to update:

```
sudo supervisorctl reread
sudo supervisorctl update
```

You can check on the status of the components by running:

```
sudo supervisorctl
status
```

You want everything to be in a running state. After that go to the FQDN or IP address of the server to complete setup: `http://your.server.ip.address:9000` 

If you specify a URL different from what you're currently connected to once setup completes you'll need to visit the updated URL as Sentry doesn't allow you to connect from ANY address other than the domain/IP specified during setup. 

That's it! Much of this guide is derived from the [official Sentry docs](https://docs.getsentry.com/on-premise/server/installation/) with more detail filled in where needed. One might say I simply noobified the guide by adding some more hand-holding.
