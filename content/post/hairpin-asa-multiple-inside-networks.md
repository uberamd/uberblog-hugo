+++
title = "How to do ASA Hairpinning with multiple Inside networks"
description = ""
author = "Steve Morrissey"
date = "2016-12-31T11:54:35-06:00"
tags = [
    "asdm",
    "networking",
    "cisco",
    "asa",
    "asav"
]

+++

## The issue

When trying to consume a service hosted inside your network via it's external IP address, which is also the outside address of your Cisco ASA, your connection will time out. 

![cisco network](/img/hairpin_asa.png)

Given the network diagram above we want to achieve the following:

1. **openshift-builder** (10.8.3.253) needs to pull down code from git server gogs.stevem.io (**107.189.44.118**) -- which according to our diagram has an internal IP of **10.8.1.254**
1. Outside interface has **107.189.44.113 /28**, meaning traffic needs to leave and re-enter via the Outside interface
1. We don't want to use DNS doctoring to achieve this, and don't want to setup split DNS -- we want to be able to use the public DNS record for gogs.stevem.io to achieve this, which resolves to **107.189.44.118**

If you tried to get 10.8.3.253 to talk to 107.189.44.118 you'd receive a connection timeout. We need to create a NAT rule for this to work as expected.

## The fix

Solving this issue is actually quite simple. First, ensure "Enable traffic between two or more hosts connected to the same interface" is checked under Configuration -> Device Setup -> Interfaces. 

Second, go to Firewall -> NAT Rules -> Add NAT Rule

![hairpin NAT](/img/hairpin_asa_nat_rule.png)

Configure as follows:

* Set **Source Interface** to the interface of the server trying to connect outbound -- in our case it's our WEB network
* Set the **Destination Interface** as the DMZ network that the external IP gets gets natted to -- in our case it's our DMZ network
* Set the **Source Address** to the network object representing where the devices trying to connect outbound live -- in our case it's once again our WEB network
* Set the **Destination Address** to the external IP of the service being consumed -- in our case it's 107.189.44.118 which is where gogs.stevem.io resolves
* Set the **Source NAT Type** to Dynamic PAT (Hide)
* Set the **Source Address** to the interface the network where the destination lives -- in our case it's the DMZ interface
* Set the **Destination Address** to the internal IP of the server you want to ultimately end up -- in our case it's the gogz-dmz-haproxy-vip object which is our Load Balancer (10.8.1.254)
* Enable the rule
* Press OK

Note that this assumes you already have a functioning NAT rule in place for traffic originating from "the internet". In my case that rule is as follows:

![hairpin NAT internet](/img/hairpin_asa_nat_rule_internet.png)
