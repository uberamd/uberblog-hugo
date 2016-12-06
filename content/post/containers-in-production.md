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

Our monitoring platform of choice is Sensu, which is absolutely fantastic. It's very different from PRTG -- you don't install it and say "Go find my devices pls" while you drink a cup of coffee. Out of box it does next to nothing, with no UI (one exists, called Uchiwa, but it isn't bundled). But the power comes from it's flexibility.  You define checks in JSON files, which get read by sensu-server processes, then scheduled out to RabbitMQ. Clients connect to RabbitMQ, grab checks applicable to their subscriptions, execute, and return the results. Finally, sensu-server processes the results and "handles" them -- fires off an email, pops a message into slack, alerts via PagerDuty, etc. Very straight forward.

## Scaling issues strike

As I mentioned earlier, being available externally with quick response times is incredibly important for the business. Because we host most of our stuff on-prem, we execute a lot of our external availability checks and metric collection from AWS, distributed between regions, in US West and East. 

We were running 2 EC2 instances per AWS region, just basic Ubuntu instances running the sensu-client agent and connecting back to our on-prem RabbitMQ endpoint. This means check scheduling is still handled by on-prem sensu-server processes. No problem. However issues started to appear as we added more and more external endpoints, and attached more and more checks to those external endpoints. Things like response time metrics, DNS resolution, SSL certificate expiration, etc. quickly put more and more pressure on those EC2 instances to perform a lot of tasks at tight 60-second intervals. Eventually the AWS nodes just couldn't keep up anymore, which was causing very strange behavior with sensu.

In this image, one region of sensu client nodes was struggling and tipping over, while the other region was operating fairly ok. However when one region seemed to recover, the other region would experience issues keeping up. It wasn't good.


## A containerized, dockerized solution

Because the checks being executed in AWS are done in a roundrobin fashion, in theory more sensu clients running in AWS means increased speed when churning through the queue of checks waiting to be run, and the more reliable our delivery of metrics will be. It also meant we could potentially increase our metric collection interval from once a minute, to once every 10 or 30 seconds. 

We had some pretty straight-forward requirements:

* Easily pack more sensu-client processes into a single EC2 instance to distribute check execution burden more widely
* Be able to easily scale up or down as we adjust what external endpoints we're monitoring, and what monitors we attach to them
* Automatically kill off problematic runaway sensu-client processes and replace them with fresh ones
* Easily deploy clients without having to worry about where they'll be running, all via our CI workflow

We decided to spin up a few EC2 instances running the ECS-optimized AMI, which is designed for Amazons EC2 Container Service offering. This gives us nice endpoints for defining what we want running on these nodes -- in our case a bunch of sensu-client containers -- and ECS will ensure we remain in that state. We can then monitor ECS and get alerted if ECS is unable to satisfy our defined requirements. It also allows us to have auto-scaling groups to assist in scaling during busy times without the need for manual intervention.

Thus, a solution was born. Create sensu-client Docker images to run on AWS ECS, and have them configurable via environment variables. No need to ship config files, etc. When we develop new checks, which must exist on the sensu-client in order for them to execute, we simply push out an updated Docker image. Pretty straight forward.

## Great success?

So far, yes. We're now 4 months in and honestly, things have been working great. We're able to take a very "set it and forget it" approach to these containers and let AWS services do their thing to ensure everything is trucking along nicely. Deployments are straight forward, and the flexibility of using environment variables for configuration has already paid off in time savings.

How? We decided it was time to rebuild our on-prem Sensu services as we started to run into the same scaling issues -- needing more sensu-server and sensu-client processes, and throwing more vCPUs at the problem wasn't helping much. Using what we built out for building and deploying sensu-client Docker images, building and deploying sensu-server Docker images was very straight forward. 

## Rebuilding on-prem sensu in containers

To start we stood up a nonprod Sensu environment, purely running in containers, and migrated about 400 of our nonprod VMs (which run the sensu-client process to collect on-box metrics and run on-box checks) over to it with some solid success. We can easily scale up and down sensu-server containers as needed, and deploy new sensu-servers, with updated handlers and extensions, in a rolling release fashion. 
