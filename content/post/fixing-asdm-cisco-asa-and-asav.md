+++
title = "Fixing ASDM Login Error on Cisco ASA and ASAv"
description = ""
author = "Steve Morrissey"
tags = [
    "cisco",
    "asa",
    "asav",
    "vmware",
    "tutorial"
]
date = "2016-12-16T11:03:40-06:00"

+++

## The problem -- ASDM Won't launch properly

When setting up a Cisco ASA Virtual Appliance (ASAv) in my lab I ran into issues getting ASDM to launch properly. When attempting to login I'd be prompted with the message "Unable to launch device manager from X.X.X.X" as seen in the screenshot below:

![ASDM Login](/img/asdm01.PNG)

![ASDM Error](/img/asdm02.PNG)

The logs indicate it's an error with how SSL is configured on the ASA:

```
Application Logging Started at Thu Dec 15 15:51:05 CST 2016
---------------------------------------------
Local Launcher Version = 1.5.7java.lang.ClassNotFoundException: com.sun.deploy.util.ConsoleController
    at java.net.URLClassLoader.findClass(UnkOK button clicked
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
    at sun.security.ssl.Alerts.getSSLException(Unknown Source)
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
    at sun.security.ssl.Alerts.getSSLException(Unknown Source)
    at sun.security.ssl.Alerts.getSSLException(Unknown Source)
    at sun.security.ssl.SSLSocketImpl.recvAlert(Unknown Source)
Trying for ASDM Version file; url = https://10.7.5.49/admin/
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
    at sun.security.ssl.Alerts.getSSLException(Unknown Source)
    at sun.security.ssl.Alerts.getSSLException(Unknown Source)
    at sun.security.ssl.SSLSocketImpl.recvAlert(Unknown Source)
    at sun.security.ssl.SSLSocketImpl.readRecord(Unknown Source)
    at sun.security.ssl.SSLSocketImpl.performInitialHandshake(Unknown Source)
    at sun.security.ssl.SSLSocketImpl.startHandshake(Unknown Source)
    at sun.security.ssl.SSLSocketImpl.startHandshake(Unknown Source)
Trying for IDM. url=https://10.7.5.49/idm/idm.jnlp/
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
    at sun.security.ssl.Alerts.getSSLException(Unknown Source)
    at sun.security.ssl.Alerts.getSSLException(Unknown Source)
    at sun.security.ssl.SSLSocketImpl.recvAlert(Unknown Source)
    at java.lang.Thread.run(Unknown Source)
```

## The fix

Luckily the fix is fairly easy. Go into the CLI of the ASA in config mode and add the following line: `ssl encryption rc4-sha1 aes128-sha1 aes256-sha1 3des-sha1`

If you don't know how to do that it looks something like this:

```
ciscoasa# conf t
ciscoasa(config)# ssl encryption rc4-sha1 aes128-sha1 aes256-sha1 3des-sha1
ciscoasa(config)# exit
```

This should clear up the login issues and allow ASDM to function as expected.
