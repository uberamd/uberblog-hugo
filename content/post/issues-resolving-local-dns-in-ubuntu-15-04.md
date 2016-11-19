+++
date = "2016-11-19T13:04:03-06:00"
title = "issues resolving .local dns in ubuntu 15.04"
description = ""
author = "Steve Morrissey"
tags = [
  "linux",
  "ubuntu"
]

+++

# The problem

After getting my Ubuntu 15.04 desktop setup I noticed Chrome/Firefox was unable to properly resolve my local domain (\*.home.local). 

For example, when trying to view the vCenter web interface at `https://vc.home.local`, or trying to SSH into my PostgreSQL development box `postgres-dev-01.home.local` I'd just get `ssh: Could not resolve hostname exit: Temporary failure in name resolution`. This was made especially odd since an nslookup was able to resolve everything just fine:

```
[~/git/stats-api]$ nslookup postgres-dev-01.home.local
Server:        10.10.254.200
Address:    10.10.254.200#53

Name:    postgres-dev-01.home.local
Address: 10.10.254.129
```

# The fix

So what gives? After searching it turns out that I needed to edit my /etc/nsswitch.conf file. Specifically, I had to move dns into a new position on the hosts: line to change it from this:

```
hosts:          files myhostname mdns4_minimal [NOTFOUND=return] dns # BAD DOESNT WORK :(
```

To this:

```
hosts:          files dns myhostname mdns4_minimal [NOTFOUND=return]
```

After making this change and restarting Chrome/Firefox my `home.local` DNS was resolving properly and I was able to SSH into local boxes.

