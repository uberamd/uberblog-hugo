+++
description = ""
author = "Steve Morrissey"
tags = [
    "ruby",
    "rails",
    "homelab",
    "lab",
    "demo",
    "hits"
]
date = "2018-11-30T22:00:00-06:00"
title = "haproxy in the homelab"

+++
HAProxy is my homelab loadbalancer of choice due to it's versatility and general ease of configuration. Whether it's HTTP or just plan TCP traffic I want to land 
within my lab, a few tweaks to an HAProxy config is all it takes. However, as I deploy more and more random services, which I want available from the internet, 
having to remote into my various HAProxy ingress servers becomes a pain. Also, since I like to have isolated HAProxy instances depending on what I'm doing, yet again 
having to remote into boxes to make changes becomes even more tiresome.


## The Solution
After playing with a few possible choices I settled on creating a Ruby on Rails application to manage deploying HAProxy configurations to my various endpoints. 
This application, which I call HITS (HAProxy Infrastructure Transformation Service), allows for defining rules, frontends, backends, and servers which ultimately 
go into a building an instance of HAProxy. It also handles issuing and renewing Lets Encrypt SSL certificates, and distributing those certificates to proper endpoints. 

## What does it look like?
Graphical design is a skill that I haven't been blessed with, so it's stock Bootstrap 4. 

### SSL Certificates
![hitssslcerts](/img/certificates.png)

From here you can issue new SSL certificates, delete existing ones, or forcefully renew.

### Rules
![rules](/img/rules.png)

This is where you define rules (ACLs), such as SSL redirects, path based redirects, etc.

### Servers
![backend servers](/img/servers.png)

These are backend servers that are available to add to backend pools.

### Backends
![backends](/img/backends.png)
![backends2](/img/backends2.png)

Backends are a collection of servers, here you can see your defined backends, and add/remove servers from them

### Frontends
![frontends](/img/frontends.png)
![frontend details](/img/frontend_detail.png)

Frontends are ingress points where rules are evaluated and traffic is redirected to backends based on the results 
of those rules. Here you attach rules, backends, and SSL certificates to frontends, define which ports they listen 
on, etc.

### Hosts
![target host](/img/target_host.png)

A target host is a server running Docker which will run your desired HAProxy configurations. You attach desired 
frontends to a host, which generates a new release of your configuration. Each configuration is a stand alone 
docker image, complete with everything needed to handle the configured traffic workloads. The docker build 
is automatically performed against the target host.

### Deployment
![release](/img/release.png)

Finally, you release your generated configuration onto the host, which makes the configuration active. You can 
easilly roll back releases using the release history.

## Wrap up

That's about it. This is a weekend lab project created to make it so I need to SSH into my various load balancers 
less often. It's not yet 100% complete (things like Where Used are not coded yet), however it is functional and 
scratches most of the itches I had around this subject. 

Before you say "hey fool, why not just use Traefik or Consul" etc. I've used them, they work great, but in my 
use case I just wanted to quickly be able to toss some endpoints on a HAProxy instance in my lab, or on my 
dedicated server, and not need to think much about service discovery, having to decom endpoints when I'm done, 
etc. This is quick and dirty "add endpoints, remove them, press a button, and it's live" solution.

Thanks for reading!
