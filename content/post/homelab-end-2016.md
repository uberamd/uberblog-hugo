+++
title = "HomeLab Revision 2016.12"
description = ""
author = "Steve Morrissey"
tags = [
    "homelab"
]
date = "2016-12-30T23:52:07-06:00"

+++

## Current network diagram

You can view the current HomeLab diagram here: [![homelab-diagram](/img/ubernets201612.png)](/img/ubernets201612.png)

For those who have never seen this before: [yes, I did run fiber out to my shed](https://www.reddit.com/r/homelab/comments/3twiy7/taking_advantage_of_the_cold_minnesota_winter/). I live in Minnesota and last winter I took advantage of the ridiculously cold winters we have and housed some servers out there.

## Major changes

Here is a list of big changes made in the current revision:

* Dedicated pfSense firewall was replaced with virtual Cisco ASAv firewall
* Replacing the firewall means I'm connecting my cable modem to my Cisco 3750 core switch
* Also replaced the virtual pfSense firewall on my dedicated server in Atlanta with a pair of active/standby ASAv firewalls
* Upgraded host-to-storage networking to 10Gb which included adding 3x10Gb interfaces to my FreeNAS box
* Moved from NFS to iSCSI for VMware datastore share in order to achieve a network configuration where I can direct connect ESXi hosts to FreeNAS while still having a single common datastore (with working vmotions, DRS, etc)
* Added an HP DL380 G7 to the lab (2x Xeon L5630, 96GB RAM, 4x 300GB 10k drives)
* Started migrating hosted projects from Kubernetes to OpenShift Origin

## Wish list

Of course these additions sparked some additions to my wish list:

* 10 or 24-port 10Gb switch
* Half-height 4-post rack
* Additional UPS

## Short-term plans

Here are some things I plan to tackle in the next 30 days:

* Clean up networks -- too much shit where it shouldn't be
* Switch config backup software (implement Rancid)
* Get dedicated ESXi server off public-facing internet -- currently my dedicated ESXi host management interface is internet-facing, which isn't ideal. I need to get this moved to be over my VPN tunnel WITHOUT making it impossible to recover should I lose my tunnel and need to restore services without vcenter access
* Implement Cisco AnyConnect VPN
* Setup VMware Horizon View again
