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

## Technologies used

Ruby on Rails for the application. Docker for building the HAProxy containers. Modified Docker API gem for doing 
docker image builds against remote endpoints. And obviously HAProxy.

## What does it look like?
Graphical design is a skill that I haven't been blessed with, so it's stock Bootstrap 4. 

### SSL Certificates
From here you can issue new SSL certificates, delete existing ones, or forcefully renew. This is all enabled 
thanks to free Lets Encrypt certificates

![hitssslcerts](/img/certificates.png)

### Rules
This is where you define rules (ACLs), such as SSL redirects, path based redirects, etc. These rules help 
ensure traffic lands where it needs to -- such as having multiple websites hosted on one IP, using host 
headers to decide which backend to land on.

![rules](/img/rules.png)


### Servers
These are backend servers that are available to add to backend pools. Backend servers run the actual applications 
HAProxy is sending traffic towards. A single backend can have one or more backend servers

![backend servers](/img/servers.png)


### Backends
Backends are a collection of servers, here you can see your defined backends, and add/remove servers from them. 
Generally, for a load balancer to actually balance traffic, you want multiple servers in a given backend.

![backends](/img/backends.png)
![backends2](/img/backends2.png)


### Frontends
Frontends are ingress points where rules are evaluated and traffic is redirected to backends based on the results 
on, etc. Frontends define which ports need to take in traffic, whether they are HTTP or regular TCP, and which 
ACLs apply to each request.

![frontends](/img/frontends.png)
![frontend details](/img/frontend_detail.png)


### Hosts
A target host is a server running Docker which will run your desired HAProxy configurations. You attach desired 
frontends to a host, which generates a new release of your configuration. Each configuration is a stand alone 
docker image, complete with everything needed to handle the configured traffic workloads. The docker build 
is automatically performed against the target host.

![target host](/img/target_host.png)


### Deployment
Finally, you release your generated configuration onto the host, which makes the configuration active. You can 
easily roll back releases using the release history.

![release](/img/release.png)


## Wrap up

That's about it. This is a weekend lab project created to make it so I need to SSH into my various load balancers 
less often. It's not yet 100% complete (things like Where Used are not coded yet), however it is functional and 
scratches most of the itches I had around this subject. 

Before you say "hey fool, why not just use Traefik or Consul" etc. I've used them, they work great, but in my 
use case I just wanted to quickly be able to toss some endpoints on a HAProxy instance in my lab, or on my 
dedicated server, and not need to think much about service discovery, having to decom endpoints when I'm done, 
etc. This is quick and dirty "add endpoints, remove them, press a button, and it's live" solution.

Thanks for reading!
