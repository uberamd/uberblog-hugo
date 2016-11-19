+++
tags = [
]
categories = [ ]
series = [ ]

title = "haproxy consul template generation with docker registrator mesosphere and marathon"
description = ""
date = "2016-11-18T12:11:14-06:00"
author = "Steve Morrissey"

+++

![Docker Consul Marathon](/img/visu-ovh-docker-lab.jpg)

Odds are if you've stumbled across this post it's because you're running into the same issue I had:  your docker-backed services are using the wrong IP in Consul-Template. Assuming your workflow looks like this:

1. Commit code change
1. CI server triggers a docker image build
1. Image is pushed to registry and API call is made to Marathon to deploy application
1. Marathon deploys the docker container with bridged networking, assigns it a random IP
1. Registrator detects the new container and registers the service with Consul
1. Consul template picks up the new container and should add another host to the HAProxy config
1. Oh shit, it doesn't work :(


I'm guessing step 6 is where the wheels come off for you. Sure, consul-template is writing out the config file, but it's writing out the docker0 interface IP address instead of the IP of the Mesosphere Slave the container is running on, right? How do we fix this while still using Bridged networking? Quite simple, actually. Ensure your consul-template file for HAProxy looks similar to this:


```
backend http_pool
  mode http
  balance roundrobin
  option forwardfor
  option httpchk GET /YOUR_HEALTH_CHECK_PATH{{range service "YOUR_SERVICE_NAME"}}
  server {{.Node}} {{with node .Node }}{{.Node.Address}}{{end}}:{{.Port}} check inter 3s fall 3 rise 2{{end}}
```


Important piece there is the final line which grabs the Node the service is running on and extracts the Address of the node itself. Most tutorials say to simply use .Address but as you likely discovered that'll leave you with the container IP, which isn't at all useful to you. 

It's that simple! 
