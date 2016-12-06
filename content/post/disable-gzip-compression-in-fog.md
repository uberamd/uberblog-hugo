+++
tags = [
  "archive",
  "fog",
  "imaging",
  "tutorial",
  "linux"
]
title = "disable gzip compression in fog"
date = "2014-08-05T13:26:16-06:00"
description = ""
author = "Steve Morrissey"

+++

This was originally posted on my old blog back in 2010ish, restored it here for archival purposes.

Recently I changed the software the imaging server at work uses from Clonezilla to FOG. There were many reasons for the change such as a better web interface, image deployment queue, etc however one of the main things I was looking forward to was storage nodes which allows for distribution of images across multiple servers to extend storage.

Deploying the FOG server was easy enough, however one of the first things I noticed was that image creation (uploading a new image to the server) was incredibly slow in comparison to image deployment. Image creation would take nearly 2 hours while image deployment would take about 25 minutes. This frustrated me to no end as we were doing this over gigabit and it wasn't utilizing hardly any of the pipe on image creation. A quick glance at the screen told me why: FOG automatically assumes you want to GZIP the image. This means a smaller image, but a drastically increased image creation time since the system needs to compress the data it is sending.

I searched high and low through the config files for a way to disable GZIP compression, but found nothing. Eventually I figured out how to disable the compression, however doing so was not well documented at all. Enter this post which will hopefully help others solve the same problem I ran into.

Simply follow these steps (type these commands in your Linux terminal, you may need to be root or sudo to run some of these):

```
cp /tftpboot/fog/images/init.gz /tmp/init.gz
cd /tmp
gunzip init.gz
mkdir tmpMnt
mount -o loop /tmp/init /tmp/tmpMnt
```

Now using your favorite linux command line editor open the file /tmp/tmpMnt/bin/fog and find and replace all instances of -z1 with -z0. To do that with VIM do the following:

```
:%s/z1/z0/
:wq
```

If you're a vim user you'll know that the above keystrokes replace z1 with z0, and :wq is a write and quit command. Once you have replaced all -z1 with -z0 we need to recompress and replace your old init.gz file:

```
cd /tmp
umount /tmp/tmpMnt
gzip -9 init
cp /tftpboot/fog/images/init.gz /tftpboot/fog/images/init.gz.old
cp -f init.gz /tftpboot/fog/images/init.gz
```

Thats it. Now you have disabled compression upon image creation and you should notice a VERY large drop in image creation time! FOG does provide a script that assists in editing the init.gz file, HOWEVER the script requires you to have Nautilus installed (aka GNOME) and how many people really run a GUI on a server? Not many.
