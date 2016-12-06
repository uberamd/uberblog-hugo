+++
tags = [
  "homelab",
  "cisco"
]
title = "homelab progress"
description = "Initial Homelab Build"
author = "Steve Morrissey"
date = "2015-07-08T14:25:07-06:00"

+++

A couple months ago I started building a homelab to assist in studying for the CCNA exam. I'm a pretty hands-on learner so having hardware that I can plug into and manipulate goes a long way. The home lab started out pretty modestly: 1x Cisco 3750 (WS-C3750-48TS-S), 1x Cisco 2980G XL, and 1x Cisco 2811 router. All of this was sitting on a 15U mini floor rack.

Over the course of the next few months I started adding components until it reached this point:

![Homelab 1](/img/homelab-1.JPG)

I'm pretty happy with how things have been working right here.  A part list from top to bottom for those curious:

 * HP ProCurve 2824 gigabit managed switch
 * Cisco 4400 WLC (wireless lan controller)
 * 3x Cisco 3750 switches in a stack (stackwise)
 * Juniper Netscreen 25 Firewall
 * Juniper SA2000 SSL VPN
 * Late 2013 MacBook Pro serving as a VMware ESXi host
 * Cisco PIX 515 Firewall
 * Cisco 2800 Router (unplugged)
 * Cisco 2811 Router
 * Cisco 1252 Wireless Access Point (attached to side of rack)

The Cisco 2811 router appears to be a pretty big bottleneck in the whole network setup as, based on my research, it's only capable of doing ~32Mbps throughput. This doesn't work well with my cable connection which can go up to 70Mbps. I've pulled out the 2811 and replaced it with a Ubiquiti EdgeRouter and am finally getting reasonable speeds.

As with all old hardware the Cisco PIX 515 firewall has been a bit of a pain in the ass with occasional crashing. Performance on the Cisco 4400 Wireless Lan Controller also seems to degrade quite rapidly throughout the week to the point where even 15Mbps of local wireless traffic from a single device is enough to choke out any other wireless client until the controller is rebooted.

You might be wondering why there is an HP ProCurve switch in a Cisco lab. Well, the ProCurve 2824 has 24 gigabit ports vs the Cisco 3750 models I have that only have 4 each (gig SFP). The HP ProCurve is also significantly cheaper than the 3750 while still being a managed switch. I'm using the ProCurves for my VMware hosts which I'll touch on at a later time.

Posts that follow will document issues and various things I'm doing with this hardware setup -- with this post serving as a baseline.

And since people always seem to ask, the electrical cost per month to run this pictured stack is ~$15.
