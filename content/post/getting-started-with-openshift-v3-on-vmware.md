+++
title = "getting started with openshift v3 on vmware"
description = ""
author = "Steve Morrissey"
tags = [
  "homelab",
  "tutorial",
  "openshift",
  "origin",
  "devops",
  "centos",
  "ansible",
  "terraform"
]
date = "2017-01-10T07:23:40-06:00"
draft = true

+++

## Goal

After following this tutorial you should end up with a functional environment running OpenShift Origin. This environment will consist of 1 Master and 4 Nodes. We will be taking advantage of the OpenShift Ansible repository to tackle a majority of the steps here. If you're looking for an in-depth guide on OpenShift see here: https://docs.openshift.org/latest/install_config/install/planning.html

## Architecture

The OpenShift documentation provides this architecture diagram:

![openshift architecture](/img/openshift-architecture.png)

Instead of using Red Hat Enterprise Linux we'll stick to CentOS 7, but the rest is pretty accurate.

Here is a rundown of the infrastructure we will be deploying and the role they fit into for the architecture diagram:

```
osomd01.home.local:
  role: master
  vcpu: 2
  memory: 4GB
  ip: 10.7.24.254
osond01.home.local:
  role: node
  vcpu: 2
  memory: 2GB
  ip: 10.7.24.253
osond02.home.local:
  role: node
  vcpu: 2
  memory: 2GB
  ip: 10.7.24.252
osond03.home.local:
  role: node
  vcpu: 2
  memory: 2GB
  ip: 10.7.24.251
osond04.home.local:
  role: node
  vcpu: 2
  memory: 2GB
  ip: 10.7.24.250
```

The DNS names follow this pattern: `oso` (openshift origin) `m|n` (master or node) `d` (development) `01` (box number). I went ahead and created DNS entries for each of these entities, and verified they are correct using nslookup:

```
$ nslookup osomd01.home.local
Server:        10.7.5.20
Address:    10.7.5.20#53

Name:    osomd01.home.local
Address: 10.7.24.254
```


## Step 0: Prerequisites

In order to properly follow this tutorial you will need a few things:

* VMware ESXi host(s)
* vCenter (optional)
* Terraform (optional)
* Ansible installed "locally"
* Functional DNS
* git (to clone `https://github.com/openshift/openshift-ansible`)

The reason vCenter and Terraform are optional is because I personally use `terraform` to deploy VMs through vCenter, but it can also just be done by cloning out a template manually, it's just a convenience thing. 

## Step 1: Create the CentOS 7 base image

You'll want to begin by installing the CentOS 7 via the x86_64 Minimal ISO (https://www.centos.org/download/). I'm assuming you know what to do here: download the ISO, upload it to your datastore in vCenter, create a new VM, and basically "next" your way through the install.
