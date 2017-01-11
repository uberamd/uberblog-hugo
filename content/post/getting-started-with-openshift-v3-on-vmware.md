+++
title = "getting started with openshift v3 on vmware"
description = "From nothing to OpenShift in a bunch of steps!"
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

|DNS Name|IP|Role|vCPU|Memory|
---|---|---|---|---|
osomd01.home.local | 10.7.24.254 | Master | 2 | 4GB
osond01.home.local | 10.7.24.253 | Node | 2 | 4GB
osond02.home.local | 10.7.24.252 | Node | 2 | 4GB
osond03.home.local | 10.7.24.251 | Node | 2 | 4GB
osond04.home.local | 10.7.24.250 | Node | 2 | 4GB
**Totals**|||12|20GB

The DNS names follow this pattern: `oso` (openshift origin) `m|n` (master or node) `d` (development) `01` (box number). I went ahead and created DNS entries for each of these entities, and verified they are correct using nslookup:

```
$ nslookup osomd01.home.local
Server:        10.7.5.20
Address:    10.7.5.20#53

Name:    osomd01.home.local
Address: 10.7.24.254
```


## Prerequisites

In order to properly follow this tutorial you will need a few things:

* VMware ESXi host(s)
* vCenter (optional)
* Terraform (optional)
* Ansible installed "locally"
* Functional DNS
* git (to clone `https://github.com/openshift/openshift-ansible`)

The reason vCenter and Terraform are optional is because I personally use `terraform` to deploy VMs through vCenter, but it can also just be done by cloning out a template manually, it's just a convenience thing. 

## Step 1: Create the CentOS 7 base image (optional)

*You can skip this step if you already have a CentOS 7 template you deploy through VMware, where root can login with your SSH key*

To begin, install CentOS 7 via the x86_64 Minimal ISO (https://www.centos.org/download/). I'm assuming you know what to do here: download the ISO, upload it to your datastore in vCenter, create a new VM, and basically "next" your way through the install. Do create a user account with the administrator box checked. 

Once the install is finished, SSH into the new VM and install updates (`sudo yum update -y`), reboot, SSH in again, and install some required packages:
```
sudo yum install -y open-vm-tools perl net-tools
```

Now that the Open VM Tools are installed, we need to copy our SSH key over to the root user so ansible can get in without a password. **From your local machine** (where you will be launching the OpenShift install from), do a:
```
ssh-copy-id root@10.7.24.2
```

Where `10.7.24.2` is the IP address of the CentOS 7 template we're building out. If you don't have `ssh-copy-id` installed and you're on a Mac, just do a `brew install ssh-copy-id`. And if you're on a Mac and don't have [Homebrew](http://brew.sh/) installed, install that as well, `brew install ssh-copy-id`, then do the previous step.

Ensure you can SSH into the box as root using your key (no password):
```
ssh root@10.7.24.2
```

Next we need to do some general cleanup of the machine by deleting the UID from the network interface:
```
sed -i '/^\(HWADDR\|UUID\)=/d' /etc/sysconfig/network-scripts/ifcfg-e*
sed -i -e 's@^ONBOOT="no@ONBOOT="yes@' /etc/sysconfig/network-scripts/ifcfg-e*
```

Finally shut the system down as no further changes are required:
```
init 0
```

In vCenter right click on the VM -> Template -> Convert to Template. **Step 1: complete!**

## Step 2: Define the infrastructure with Terraform (optional)

*You can skip this step if you have no desire to use Terraform to create the VMs and want to make them by hand instead. Having said that, after this step it's assumed you will have the 5 VMs up and running*

So what is terraform? Taken directly from the documentation:

> Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions.

Knowing that, what we're going to do is create a file that spells out what we want our server infrastructure to look like. It will define 5 VMs: 1x Master and 4x Nodes. It will define the IP addresses, base VMware Template to use, and how much vCPU and Memory each one should have.

Assuming you already have terraform on your machine (if not you can download it [here](https://www.terraform.io/downloads.html), create a terraform file that looks somewhat like this:
```
# SET YOUR VCENTER CONNECTION INFORMATION HERE
provider "vsphere" {
  user           = "YOUR_VCENTER_USERNAME"
  password       = "YOUR_VCENTER_PASSWORD"
  vsphere_server = "YOUR_VCENTER_HOSTNAME" allow_unverified_ssl = "true"
}

# DEFINE YOUR RESOURCES HERE FOLLOWING THIS TEMPLATE, REPLACING VALUES AS REQUIRED
resource "vsphere_virtual_machine" "osomd01" {
  name   = "osomd01"
  datacenter = "HomeLab"
  vcpu   = 2
  memory = 4096
  domain = "home.local"
  dns_suffixes = ["home.local"]
  dns_servers = ["10.7.5.20", "10.7.5.30"]

  network_interface {
    label = "OPENSHIFT_DEV_vlan24"
    ipv4_address = "10.7.24.254"
    ipv4_prefix_length = "24"
    ipv4_gateway = "10.7.24.1"
  }

  disk {
    template = "Templates/basecentos"
    datastore = "freenasblock01"
    type = "thin"
  }
}

resource "vsphere_virtual_machine" "osond01" {
  name   = "osond01"
  datacenter = "HomeLab"
  vcpu   = 2
  memory = 2048
  domain = "home.local"
  dns_suffixes = ["home.local"]
  dns_servers = ["10.7.5.20", "10.7.5.30"]

  network_interface {
    label = "OPENSHIFT_DEV_vlan24"
    ipv4_address = "10.7.24.253"
    ipv4_prefix_length = "24"
    ipv4_gateway = "10.7.24.1"
  }

  disk {
    template = "Templates/basecentos"
    datastore = "freenasblock01"
    type = "thin"
  }
}

resource "vsphere_virtual_machine" "osond02" {
  name   = "osond02"
  datacenter = "HomeLab"
  vcpu   = 2
  memory = 2048
  domain = "home.local"
  dns_suffixes = ["home.local"]
  dns_servers = ["10.7.5.20", "10.7.5.30"]

  network_interface {
    label = "OPENSHIFT_DEV_vlan24"
    ipv4_address = "10.7.24.252"
    ipv4_prefix_length = "24"
    ipv4_gateway = "10.7.24.1"
  }

  disk {
    template = "Templates/basecentos"
    datastore = "freenasblock01"
    type = "thin"
  }
}

resource "vsphere_virtual_machine" "osond03" {
  name   = "osond03"
  datacenter = "HomeLab"
  vcpu   = 2
  memory = 2048
  domain = "home.local"
  dns_suffixes = ["home.local"]
  dns_servers = ["10.7.5.20", "10.7.5.30"]

  network_interface {
    label = "OPENSHIFT_DEV_vlan24"
    ipv4_address = "10.7.24.251"
    ipv4_prefix_length = "24"
    ipv4_gateway = "10.7.24.1"
  }

  disk {
    template = "Templates/basecentos"
    datastore = "freenasblock01"
    type = "thin"
  }
}

resource "vsphere_virtual_machine" "osond04" {
  name   = "osond04"
  datacenter = "HomeLab"
  vcpu   = 2
  memory = 2048
  domain = "home.local"
  dns_suffixes = ["home.local"]
  dns_servers = ["10.7.5.20", "10.7.5.30"]

  network_interface {
    label = "OPENSHIFT_DEV_vlan24"
    ipv4_address = "10.7.24.250"
    ipv4_prefix_length = "24"
    ipv4_gateway = "10.7.24.1"
  }

  disk {
    template = "Templates/basecentos"
    datastore = "freenasblock01"
    type = "thin"
  }
}
```

Obviously you will need to change a LOT of the fields including: `datacenter`, `domain`, `dns_suffixes`, `dns_servers`, `network_interface:label`, `network_interface:ipv4_address`, `network_interface:ipv4_gateway`, `disk:template`, `disk:datastore`. The `disk:template` should reference the path to the template we created in the previous step.

Once you have the file created, apply it and wait for the VMs to be created:
```
terraform apply
```

When the process completes you will see a message similar to this: **Apply complete! Resources: 5 added, 0 changed, 0 destroyed.**

You should now be able to ping each machine and SSH into them as the `root` user:
```
$ ping -c 1 osomd01.home.local
PING osomd01.home.local (10.7.24.254) 56(84) bytes of data.
64 bytes from osomd01.home.local (10.7.24.254): icmp_seq=1 ttl=63 time=0.239 ms

--- osomd01.home.local ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.239/0.239/0.239/0.000 ms
```

Great! Remember, you want your DNS entries created before going on!

## Step 3: Download the OpenShift Ansible playbooks

By the time you've reached this point you should have 5 VMs running, with DNS entries, and the ability to SSH from your machine into each one as the root user using key-based authentication. If you can't do this then stop and figure out what's wrong. If things are working thus far we're ready to download the Ansible playbooks and start cracking on the setup process.

You **must** have Ansible on your machine to continue. If you don't, download and install it (it is 100% free): http://docs.ansible.com/ansible/intro_installation.html

Next, clone the OpenShift Ansible repository to your local machine and change into the directory:
```
git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible
```

Next we need to create an inventory file for what our setup will look like. Name this file `openshift_inventory` and modify the contents to look like this (subbing values where needed):
```
[OSEv3:children]
masters
nodes

[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=root

deployment_type=origin
openshift_master_default_subdomain=apps.home.local
osm_default_node_selector='region=us-central'
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/htpasswd'}]

[masters]
osomd01.home.local

[nodes]
osomd01.home.local openshift_node_labels="{'region': 'infra', 'zone': 'mpls'}" openshift_schedulable=true
osond01.home.local openshift_node_labels="{'region': 'us-central', 'zone': 'mpls'}" openshift_schedulable=true
osond02.home.local openshift_node_labels="{'region': 'us-central', 'zone': 'mpls'}" openshift_schedulable=true
osond03.home.local openshift_node_labels="{'region': 'us-central', 'zone': 'mpls'}" openshift_schedulable=true
osond04.home.local openshift_node_labels="{'region': 'us-central', 'zone': 'mpls'}" openshift_schedulable=true
```

Here is a breakdown of the fields you probably care about:

|Section|Variable|Description|
---|---|---
OSEv3:vars | ansible_ssh_user | Indicates which user must have access over SSH to each node. In our case we're using root
OSEv3:vars | openshift_master_default_subdomain | This value will be used for project DNS entries. For example, if I make a project named blog, my route will be blog.apps.home.local.
OSEv3:vars | osm_default_node_selector | This variable overrides the node selector that projects will use by default when placing application pods
OSEv3:vars | openshift_master_identity_providers | Here we're indicating that we want to use htpasswd file-based authentication located at `/etc/origin/htpasswd`
nodes | openshift_node_labels | Defines Kubernetes labels applied to each node. In my case I'm in Minnesota so I have *us-central* as the `region`, with *Minneapolis* (mpls) as the `zone`. Adjust accordingly ensuring the region matches with the `osm_default_node_selector`

Once you're done with the inventory file we're ready to kick off the ansible job. Do that by running (from the `openshift-ansible` directory):
```
ansible-playbook -i openshift_inventory playbooks/byo/config.yml
```

Output should immediately start flying across the screen indicating ansible is churning through all the roles in the byo/config.yml playbook:
```
PLAY [Create initial host groups for localhost] ********************************

TASK [include_vars] ************************************************************
ok: [localhost]

TASK [add_host] ****************************************************************
ok: [localhost] => (item=osomd01.home.local)
ok: [localhost] => (item=osond04.home.local)
ok: [localhost] => (item=osond03.home.local)
ok: [localhost] => (item=osond02.home.local)
ok: [localhost] => (item=osond01.home.local)

PLAY [Create initial host groups for all hosts] ********************************

TASK [include_vars] ************************************************************
ok: [osomd01.home.local]
ok: [osond02.home.local]
ok: [osond01.home.local]
ok: [osond03.home.local]
ok: [osond04.home.local]

PLAY [Populate config host groups] *********************************************
...
...
PLAY RECAP *********************************************************************
localhost                  : ok=12   changed=0    unreachable=0    failed=0
osomd01.home.local         : ok=436  changed=119  unreachable=0    failed=0
osond01.home.local         : ok=152  changed=54   unreachable=0    failed=0
osond02.home.local         : ok=152  changed=54   unreachable=0    failed=0
osond03.home.local         : ok=152  changed=54   unreachable=0    failed=0
osond04.home.local         : ok=152  changed=54   unreachable=0    failed=0
```

Hopefully it completes without errors. If it did, we're in solid shape.

## Step 4: Validate the nodes are visible and create user account

We now need to SSH into the Master and become root (either SSH in as root, or do a `sudo -i`). This will give us access to the OpenShift command line directly from the master node, no additional authentication required.

First, lets check to verify the nodes are alive. Issue the following command:
```
oc get no
```

It should return back a list of nodes and their health status:
```
NAME                 STATUS    AGE
osomd01.home.local   Ready     10m
osond01.home.local   Ready     10m
osond02.home.local   Ready     10m
osond03.home.local   Ready     10m
osond04.home.local   Ready     10m
```

Perfect, everything shows as ready. Now we need to check to see if the critical services, such as the registry and router, were deployed properly. The router is what receives incoming HTTP/HTTPS requests and directs them to the proper running application, where as the registry is just a Docker registry:
```
oc get svc
```

That will display a list of running services:
```
NAME               CLUSTER-IP      EXTERNAL-IP   PORT(S)                   AGE
docker-registry    172.30.64.231   <none>        5000/TCP                  11m
kubernetes         172.30.0.1      <none>        443/TCP,53/UDP,53/TCP     18m
registry-console   172.30.100.83   <none>        9000/TCP                  10m
router             172.30.58.70    <none>        80/TCP,443/TCP,1936/TCP   11m
```

As you can see, the router and docker registry are running as desired. Awesome. Note down the **CLUSTER-IP** of the docker-registry service, we'll need that soon.

Finally, lets create a user account for access via the UI and CLI tool:
```
htpasswd /etc/origin/htpasswd your_username_here
```

## Step 5: Allow insecure access to the docker registry

Now that OpenShift is deployed to the 5 machines we need to allow them to access the Docker registry "insecurely". When Docker pulls down images it prefers to do so securely, over an encrypted connection. The Docker registry OpenShift deploys, however, is not a secured registry from the perspective of the deployed nodes. SSH into **each one of the masters and nodes** (all 5 machines one by one) and ensure the **/etc/sysconfig/docker** looks like this (replacing *172.30.64.231* with the IP of the docker-registry service you obtained when running `oc get svc`):
```
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
OPTIONS=' --selinux-enabled --log-driver=json-file --log-opt max-size=50m'
if [ -z "${DOCKER_CERT_PATH}" ]; then
        DOCKER_CERT_PATH=/etc/docker
        fi

# If you want to add your own registry to be used for docker search and docker
# pull use the ADD_REGISTRY option to list a set of registries, each prepended
# with --add-registry flag. The first registry added will be the first registry
# searched.
#ADD_REGISTRY='--add-registry registry.access.redhat.com'

# If you want to block registries from being used, uncomment the BLOCK_REGISTRY
# option and give it a set of registries, each prepended with --block-registry
# flag. For example adding docker.io will stop users from downloading images
# from docker.io
# BLOCK_REGISTRY='--block-registry'

# If you have a registry secured with https but do not have proper certs
# distributed, you can tell docker to not look for full authorization by
# adding the registry to the INSECURE_REGISTRY line and uncommenting it.
# INSECURE_REGISTRY='--insecure-registry'
INSECURE_REGISTRY='--insecure-registry 172.30.64.231:5000'

# On an SELinux system, if you remove the --selinux-enabled option, you
# also need to turn on the docker_transition_unconfined boolean.
# setsebool -P docker_transition_unconfined 1

# Location used for temporary files, such as those created by
# docker load and build operations. Default is /var/lib/docker/tmp
# Can be overriden by setting the following environment variable.
# DOCKER_TMPDIR=/var/tmp

# Controls the /etc/cron.daily/docker-logrotate cron job status.
# To disable, uncomment the line below.
# LOGROTATE=false
#

# docker-latest daemon can be used by starting the docker-latest unitfile.
# To use docker-latest client, uncomment below line
#DOCKERBINARY=/usr/bin/docker-latest
```

Then restart Docker on the VM:
```
systemctl restart docker
```

Remember to perform this step on the master and ALL of the nodes.

## Step 6: Login via the web interface -- Hello World!

Now it's time to ditch the pesky command line (for the time being) and visit the OpenShift Origin web interface. Woohoo! You can access it by visiting:
```
https://master.server.dns.name:8443/
```

In my case the URL is `https://osomd01.home.local:8443/`. If everything works you will see a login page where you can authenticate using the credentials added during step 4.

![openshift new project page](/img/openshift-ui-1.png)

Click on New Project, name it hello-world, and click Create:

![openshift new project page](/img/openshift-ui-3.png)

Click on Import YAML/JSON and paste this into the text area, then click create again:
```
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "hello-openshift",
    "creationTimestamp": null,
    "labels": {
      "name": "hello-openshift"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "hello-openshift",
        "image": "openshift/hello-openshift",
        "ports": [
          {
            "containerPort": 8080,
            "protocol": "TCP"
          }
        ],
        "resources": {},
        "volumeMounts": [
          {
            "name":"tmp",
            "mountPath":"/tmp"
          }
        ],
        "terminationMessagePath": "/dev/termination-log",
        "imagePullPolicy": "IfNotPresent",
        "capabilities": {},
        "securityContext": {
          "capabilities": {},
          "privileged": false
        }
      }
    ],
    "volumes": [
      {
        "name":"tmp",
        "emptyDir": {}
      }
    ],
    "restartPolicy": "Always",
    "dnsPolicy": "ClusterFirst",
    "serviceAccount": ""
  },
  "status": {}
}
```

That will bring you to a Project view, and you should see a single running pod:

![openshift new project page](/img/openshift-ui-4.png)

Great! This means we're able to schedule pods successfully. "What the hell is a pod?" is most likely what you're thinking right now. Here is a small summary from the [Kubernetes documentation](http://kubernetes.io/docs/user-guide/pods/): 

> A pod (as in a pod of whales or pea pod) is a group of one or more containers (such as Docker containers), the shared storage for those containers, and options about how to run the containers. Pods are always co-located and co-scheduled, and run in a shared context. A pod models an application-specific “logical host” - it contains one or more application containers which are relatively tightly coupled — in a pre-container world, they would have executed on the same physical or virtual machine.

I encourage you to read about Pods, Services, and Deployments as they are Kubernetes topics that relate heavily to OpenShift under the hood.

Lastly, we should verify the pod is actually working. For this we need to SSH back into the Master as root. This time we're going to execute a command to show the various namespaces that exist:
```
oc get namespace
```

Which returns the namespaces, the one we're interested in is the `hello-world` namespace we created:
```
NAME               STATUS    AGE
default            Active    50m
hello-world        Active    14m
kube-system        Active    50m
logging            Active    43m
management-infra   Active    49m
openshift          Active    50m
openshift-infra    Active    50m
```

What we want to do is get a list of pods running within that namespace. We should see only one:
```
oc --namespace=hello-world get pods
```

```
NAME              READY     STATUS    RESTARTS   AGE
hello-openshift   1/1       Running   0          13m
```

Finally, lets view the details of this pod:
```
oc --namespace=hello-world describe pod hello-openshift
```

You will get a bunch of detailed output about the pod. The piece we care about is the IP and Port:
```
Name:            hello-openshift
Namespace:        hello-world
Security Policy:    restricted
Node:            osond03.home.local/10.7.24.251
Start Time:        Tue, 10 Jan 2017 19:23:29 +0000
Labels:            name=hello-openshift
Status:            Running
IP:            10.131.0.2
Controllers:        <none>
Containers:
  hello-openshift:
    Container ID:    docker://130bbf5f71f0797364ac2654412319294bfb41363a35e4092ae35b19c11afc6e
    Image:        openshift/hello-openshift
    Image ID:        docker://sha256:328a278237fbb2d56cba0f71999e894d0c8cb7e01a907afca93e6e3e5a037fe2
    Port:        8080/TCP
    State:        Running
      Started:        Tue, 10 Jan 2017 19:23:35 +0000
    Ready:        True
    Restart Count:    0
    Volume Mounts:
      /tmp from tmp (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-8u288 (ro)
    Environment Variables:    <none>
Conditions:
  Type        Status
  Initialized     True
  Ready     True
  PodScheduled     True
Volumes:
  tmp:
    Type:    EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
  default-token-8u288:
    Type:    Secret (a volume populated by a Secret)
    SecretName:    default-token-8u288
QoS Tier:    BestEffort
Events:
  FirstSeen    LastSeen    Count    From                SubobjectPath                Type        Reason        Message
  ---------    --------    -----    ----                -------------                --------    ------        -------
  14m        14m        1    {default-scheduler }                            Normal        Scheduled    Successfully assigned hello-openshift to osond03.home.local
  14m        14m        1    {kubelet osond03.home.local}    spec.containers{hello-openshift}    Normal        Pulling        pulling image "openshift/hello-openshift"
  14m        14m        1    {kubelet osond03.home.local}    spec.containers{hello-openshift}    Normal        Pulled        Successfully pulled image "openshift/hello-openshift"
  14m        14m        1    {kubelet osond03.home.local}    spec.containers{hello-openshift}    Normal        Created        Created container with docker id 130bbf5f71f0
  14m        14m        1    {kubelet osond03.home.local}    spec.containers{hello-openshift}    Normal        Started        Started container with docker id 130bbf5f71f0
```

Running a curl against that IP and port combo should return back a success message:
```
[root@osomd01 ~]# curl 10.131.0.2:8080
Hello OpenShift!
```

## Step 7: Install the oc tool locally

As a final step we will want to ensure you have the OpenShift CLI tool, `oc`, installed on your local machine. The binary can be downloaded from the Releases page for OpenShift Origin: https://github.com/openshift/origin/releases

Simply download, extract, and move into your preferred path (~/bin, /usr/local/bin, etc). We want to use this tool to login to our newly created environment:
```
oc login https://osomd01.home.local:8443
```

You should see **Login successful.** Remember to use the credentials we created earlier. Using `oc` you can manage your projects and applications within OpenShift quite easily. Basically everything you can do via the UI you can do using `oc` as well. For example, `oc get pods` will show running pods, `oc get services` will show configured services, etc.

You will notice that cluster level commands, such as `oc get nodes`, will fail due to permissions issues. This is because the user you created has restricted permissions. If you wish to increase the permission level that's something you can do on your own.

## Closing thoughts

OpenShift is an incredibly powerful, useful tool for deploying applications and managing containers. Much of what OpenShift does under the hood is powered by Kuberentes, so learning how Kubernetes works, and it's terminology, is incredibly valuable. 

If you have any questions feel free to ask and I'll do by best to address them. 
