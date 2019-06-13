+++
description = ""
author = "Steve Morrissey"
tags = [
    "ruby",
    "rails",
    "homelab",
    "lab",
    "demo",
    "labman"
]
date = "2019-06-12T22:00:00-06:00"
title = "homelab management with labman"

+++
![labman](/img/services.png)

Recently I decided to try and throw together a one stop shop for managing frequently performed actions in my homelab. The goal was to 
enable me to faster create VMs, test software, rip them down, and rebuild. This is where I started with LabMan - HomeLab Manager.

It is very alpha. Very very alpha. It consists of 2 components: a Rails application that handles background jobs and the web UI, and an agent 
written in Go that runs on the servers and checks them in while providing some general info such as installed packages.

At a glance features:

* Create new VMs
* IPAM
* Execute workflows against hosts
* Host monitoring
* Host firewall management
* DNS management
* Network device configuration
* Network visualization
* Alerting
* Service monitoring


# Picture Walkthrough

## Hosts View
Shows hosts in the lab, a glimpse of their health, IP, and when the labman agent last checked in (WIP).

![labman](/img/labman_hosts.png)

## Single Host View - Dashboard
This view allows you to see a dashboard with some metrics about a given host (CPU, RAM, Network, etc)

![labman](/img/labman_host.png)

## Single Host View - Workflow
Shows information about workflows that have run against this host (more on that later).

![labman](/img/host_workflow.png)

## Single Host View - Firewall
Allows you to visually manipulate firewall rules which apply to this host.

![labman](/img/host_firewall.png)

![labman](/img/host_firewall2.png)

## Single Host View - Alarms
Shows alarms running against this host, their current status, and exit codes from alarm runs (0=ok, 1=warning, 2=critical)

Alarm notifications are sent through slack.

![labman](/img/host_alarms.png)

![labman](/img/host_alarms2.png)

## Single Host View - Console
Access a VMware Console view to interact with VMs having network issues, etc. HTML5

![labman](/img/host_console.png)

## Single Host View - Configuration
Enable/disable alarms, set SSH access information, and even reprovision or deprovision the VM.

![labman](/img/host_configuration.png)

## Create a new VM
Wizard walks through VM creation and kicks off a provisioning workflow (more info later).

![labman](/img/newvm1.png)

![labman](/img/newvm2.png)

![labman](/img/newvm3.png)

![labman](/img/newvm4.png)

## Network Devices
Show dashboard of network devices

![labman](/img/netdev.png)

## Network Devices - Interfaces
Show interfaces, connections, and even update the configuration of an interface (Cisco devices supported right now)

![labman](/img/netdev_iface.png)

![labman](/img/netdev_editiface.png)

## Network Devices - Visualization
Show connections between physical devices

![labman](/img/netdev_visual2.png)

## IPAM
Show subnets in parent-child view, VLANs, and utilization

![labman](/img/ipam.png)

![labman](/img/ipam_subnet.png)

## IPAM - Subnet View
Show subnet details, utilization, hosts, DHCP scopes, etc. Subnets are automatically swept to detect new hosts. IP, Host, DNS, and Network Device 
objects are displayed to associated IPs.

![labman](/img/ipam_subnet2.png)

![labman](/img/ipam_subnet3.png)

![labman](/img/ipam_subnet4.png)

## DNS - Server View
Show all zones on a DNS server

![labman](/img/dns.png)

## DNS - Zone View
Show records for a DNS zone, create new records, delete stale records.

![labman](/img/dns2.png)

![labman](/img/dns3.png)

## Services
List services and their availability

![labman](/img/services.png)

## Services - Parent Service with Children
Show a service, and subservices, with their health status

![labman](/img/services2.png)

![labman](/img/services3.png)


## Workflows
Shows workflows that have been created, as well as lists workflows that have been run. This includes host provisioning.

![labman](/img/workflows1.png)

![labman](/img/workflows2.png)

## Workflows - Create Workflow
Create a workflow by defining steps to perform against a host.

![labman](/img/workflows3.png)

## Workflow - Run Example
Install Consul workflow run example

![labman](/img/workflows4.png)

## Workflow - Provision Host
Example host provisioning workflow run. Creates DHCP entry, DNS record, PXE boots, configures, validates connectivity.

![labman](/img/workflows5.png)

![labman](/img/workflows6.png)

## Workflow - Deprovision Host
Destroys VM, removes DHCP static record, removes DNS record.

![labman](/img/workflows7.png)

## Alarms
Shows all alarms and their current state. Alarm notifications are sent through slack.

![labman](/img/alarms1.png)

## Alarms - Single alarm view
Shows a single alarm, current state, and history

![labman](/img/alarms2.png)