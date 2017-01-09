+++
author = "Steve Morrissey"
tags = [
    "openshift",
    "docker"
]
title = "moving to hugo"
description = "out with the old, in with something different"
date = "2016-12-06T23:44:11-06:00"

+++

## Custom beginnings

Back in 2014 I wrote a simple blog CMS in Ruby on Rails. It didn't have the most features in the world but did have all the functionality I needed at the time, which included:

* Uploading images to AWS S3 and storing multiple sizes
* Visual editor for the Admin area
* Post tagging
* Syntax highlighting
* Comment system

It was pretty barebones but worked well enough. There was one major "shortcoming", and that was the reliance on a database for storing posts. While that might sound like an odd complaint, it did make it a pain in the ass to move the blog between various hosting methods. Given my proclivity for playing around with different ways to deploy software, having to shuffle postgres database backups around constantly was a big hassle.

## Go-ing to something better

While learning the Go programming language I stumbled across a project named [Hugo](https://gohugo.io/overview/introduction/), which is a static site generator that allows for writing content in Markdown syntax and building out static HTML files. Since shipping around static files is much easier than managing both an application and a database it seemed like the right direction to move. The **build** -> **deploy** workflow is incredibly simple, and the hugo binary is able to serve the content without needing to use Apache/Nginx. 

I'm also publishing the source for this blog on my git server as there is no need to keep these static files private: https://gogs.stevem.io/uberamd/uberblog-hugo

## New PaaS

![OpenShift Logo](/img/openshift.png)

Along with redoing the site with Hugo, I've started using [OpenShift Origin v3](https://docs.openshift.org/latest/welcome/index.html) hosted on my dedicated server in Atlanta. A while back I used the older version of OpenShift, however the learning curve that came with v3 was a bit much given my limited knowledge of containers (the previous version was a more traditional PaaS like Heroku). For those who don't know OpenShift, it builds on top of Kubernetes, which is a collection of tools for managing containers. Kubernetes is absolutely awesome, and can easily be used to do cool stuff without OpenShift.

Given the move to a PaaS solution the migration of the original Rails app went like this: Hosted on a standalone VM -> Hosted on OpenShift v2 -> Dockerized -> Mesosphere -> Nomad -> Kubernetes -> OpenShift v3. It should now be clear why migrating docker containers and a database between each of these hosting methods was a pain in the butt and why static files made more sense.

I'm making a writeup about OpenShift Origin v3 and how to get it setup on-prem which I'll be publishing shortly. It's a truly awesome tool that has a bit of a learning curve -- but is worth understanding.

I'll likely also release the source for my Rails blogging solution once I have a chance to clean up the code a bit.
