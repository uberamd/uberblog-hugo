+++
tags = [
  "docker",
  "containers",
  "devops"
]
title = "containers in production"
description = "maybe not that ridiculous after all"
author = "Steve Morrissey"
date = "2016-12-06T07:42:49-06:00"

+++

## Quick background

My job involves doing "DevOpsy" things for a company that develops and hosts APIs for clients. These APIs are the backends to various services you've likely heard of or interacted with at some point in time. Because our clients depend on the performance and availability of our exposed services, monitoring is one of our top priorities. Without flexible, reliable, code-driven monitoring we're setting ourselves up for failure.

Our monitoring platform of choice is [Sensu](https://sensuapp.org/features), which is an absolutely fantastic piece of open source goodness. It's very different from PRTG -- you don't double click an MSI then say "Go find my devices pls" while you drink a cup of coffee. Out of box it does next to nothing, with no UI (one exists, called Uchiwa, but it isn't bundled). But the power comes from it's flexibility.  You define checks in JSON files, which get read by sensu-server processes, then scheduled out to RabbitMQ. Clients connect to RabbitMQ, grab checks applicable to their subscriptions, execute, and return the results. Finally, sensu-server processes the results and "handles" them -- fires off an email, pops a message into slack, alerts via PagerDuty, etc. 

The driving factor behind adopting a system like this is that you get alerted on things you care about and can easily extend the functionality by writing custom code.

Here is the architecture diagram from the official Sensu site to visually see the components of a Sensu environment:

![sensu architecture gif](/img/sensu-diagram.gif)

Note that Sensu can also act in a standalone fashion where clients schedule and execute checks on their own (without a sensu-server telling the client when to do it) and return the results for processing, however that doesn't fit with our deployment workflows as it makes adding new checks to every server a pain. The way we do it simply requires a client to subscribe to "something", and we can adjust which checks "something" subscribers need to execute with ease.

## Scaling issues strike

As I mentioned earlier, being available externally with quick response times is incredibly important for the business. Because we host most of our stuff on-prem, we execute a lot of our external availability checks and metric collection from AWS, distributed between regions, in US West and East. 

We were running 2 EC2 instances per AWS region, just basic Ubuntu instances running the sensu-client agent and connecting back to our on-prem RabbitMQ endpoint. This means check scheduling is still handled by on-prem sensu-server processes. No problem. However issues started to appear as we added more and more external endpoints, and attached more and more checks to those external endpoints. Things like response time metrics, DNS resolution, SSL certificate expiration, etc. quickly put more and more pressure on those EC2 instances to perform a lot of tasks at tight 60-second intervals. Eventually the AWS nodes just couldn't keep up anymore, which was causing very strange behavior with sensu.

![aws load average](/img/awsload.png)

In this image, one region of sensu client nodes was struggling and tipping over, while the other region was operating fairly ok. However when one region seemed to recover, the other region would experience issues keeping up. It wasn't good.


## A containerized, dockerized solution

Because the checks being executed in AWS are done in a roundrobin fashion, in theory more sensu clients running in AWS means increased speed when churning through the queue of checks waiting to be run, and the more reliable our delivery of metrics will be. It also meant we could potentially increase our metric collection interval from once a minute, to once every 10 or 30 seconds. 

We had some pretty straight-forward parameters to determine if the container strategy would work for us:

* Must be able to pack more sensu-client processes into a single EC2 instance to distribute check execution burden across more processes
* Be able to easily scale up or down as we adjust what external endpoints we're monitoring, and/or what monitors we attach to these endpoints
* Automatically kill off problematic runaway sensu-client processes and replace them with fresh ones
* Easily deploy clients without having to worry about where they'll be running, aka same image for on prem/AWS/Azure, all via our CI workflow

To kick things off a few EC2 instances running the ECS-optimized AMI were created. This AMI is designed for Amazons EC2 Container Service offering which gives us nice endpoints for defining what "services" want running on these instances -- in our case a bunch of sensu-client containers -- and ECS will ensure we remain in that state. We can then monitor ECS and get alerted if ECS is unable to satisfy our defined requirements, whether that be to an instance dying or a bad deploy. It also allows us to have auto-scaling groups to assist in scaling EC2 instances and container quantity during busy times without the need for manual intervention. This is important -- I hate doing things manually.

With the AWS infrastructure setup I simply had to create sensu-client Docker images, and have them configurable via environment variables. No need to ship config files, etc. I drank the [12-factor](https://12factor.net/) kool-aid. When we develop new sensu plugins, which must exist on the sensu-client in order for them to execute when called via check definitions, we simply push out an updated Docker image and things just work as intended.

## Success?

So far, yes. We're now 6 months in, and honestly things have been working great. We're able to take a very "set it and forget it" approach to these containers and let AWS services do their thing to ensure everything is trucking along nicely. Deployments are clean, easy to manage, and the flexibility of using environment variables for configuration has already paid off in time savings. One of the pain points when it comes to containers is shipping config files -- something that simply using environment variables can generally solve.

Every now and then I get a notification in slack that a container in AWS is failing it's keepalive check (aka it's dead) but it always recovers -- exactly as it's supposed to. We haven't run into any of the horror stories people seem to parrot about Docker in production -- whether that be kernel panics or otherwise -- not yet at lest.

We also decided it was time to rebuild our on-prem Sensu services as we started to run into the same scaling issues -- needing more sensu-server and sensu-client processes, as throwing more vCPUs at the problem wasn't helping much. It didn't make a whole lot of sense to spin up more VMs using our ansible roles targeted at just our specific on-prem setup when what we did with containers for the sensu-client was working so well. Thus, using what we built out for building and deploying sensu-client Docker images, we took on the task of dockerizing the rest of the components (sensu-server, sensu-api). Ok, that's a bit dramatic, it was actually insanely simple.

## Rebuilding on-prem sensu in containers

To start we stood up a nonprod Sensu environment, purely running in containers (api, client, and server containers), and migrated about 400 of our nonprod VMs (which run the sensu-client process to collect on-box metrics and run on-box checks) over to it. A few bumps in the road were encountered, though it was due to my stupidity more than anything (note to self: don't release new Sensu handlers in parallel with such a major change -- makes it hard to track down the cause of slowness). Now that everything is containerized and running in our scheduler we can easily scale up and down Sensu containers as needed, and deploy new Sensu containers with updated handlers and extensions, in a rolling release fashion. And if thing's deploy poorly and won't start up, we can easily roll back to the last functional image.

It also means that deployments of new images are as simple as a CI build and 1 API call.

## Reusability

Finally, now that every component of the monitoring platform is running in a container, and proven to work both on-prem and in the cloud, we're able to take our images and reuse them. The company I work for has multiple geographically dispersed entities that run their own monitoring solutions (PRTG, Nagios, who knows what else), but now that we're able to ship them our docker images we can get them standardized on the same product. This will allow us to reuse our automation across office locations, provide a single pane-of-glass UI (which we're building custom in-house, it's pretty neat), and help ensure all teams across the org are moving away from clunky products and over to code-driven services with restful APIs. 

We want to do away with the manual way of deploying and managing solutions, and if a product doesn't have a solid API it likely should be replaced with something that does, because being able to integrate services together and automate them in a transparent way is key to building infrastructure that doesn't require a sysadmin to manually manage it.

## Beyond Sensu

We're actively using Docker for more than just monitoring now, and with a bit of service discovery it's actually proven to be quite powerful. Not only is it great for quickly deploying development/POC software, but it makes for great production user-facing service workflows as well. I'm writing up another post up on how service discovery magic makes deploying user-facing services a breeze.
