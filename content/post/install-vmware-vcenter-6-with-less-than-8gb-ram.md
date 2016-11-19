+++
title = "install vmware vcenter 6 with less than 8gb ram"
date = "2016-11-19T14:03:31-06:00"
description = ""
author = "Steve Morrissey"
tags = [
  "vmware",
  "homelab",
  "tutorial",
  "windows"
]

+++

Perhaps the most frustrating thing about vCenter 6 is the hard 8GB of RAM requirement to simply install the application on a Windows server. To a lot of people, including myself, carving out 8GB of RAM VM in a home lab just to run vCenter for a host or two is a big ask. 

But beyond that, even if you're using a physical computer that has exactly 8GB of installed RAM, if any of that RAM goes to an integrated video card, and thus doesn't appear available to Windows, you'll be blocked from running the VCenter installer as your system will have slightly less than a full 8GB of RAM. Lucky for us the solution is quite simple, and it's to run the installer with `SKIP_HARDWARE_CHECKS=1`. 

To do this simply open a PowerShell window, cd into the directory where the VMware-vCenter-Server.exe installer lives, and run the installer with an extra flag:

```
PS C:\Users\smorrissey\Desktop\vCenter-Server> .\VMware-vCenter-Server.exe "SKIP_HARDWARE_CHECKS=1"
```

That's it. The installer should start right up and not bug you about not having exactly 8GB of RAM. Success! 

![VMware 6](/img/vmvware6-lt-8g-ram.png)
