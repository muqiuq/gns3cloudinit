# Easily replicable GNS3 Lab

I found myself wanting to use GNS3 in class. The students should work in groups. I didn't want to loose to much time providing 1st level support to every student to get GNS3 up and running. Besides I had no garantee that the laptops they owned had enough processing power and RAM. 

The decision: Build a proxmox cluster and automatically deploy the virtual machines containing GNS3. 

**Special requirement:** The students should be able to communicate with the GNS3 lab like the would if they connected their PC with a ethernet cable. Thats why I used OpenVPN and added a virtual bridge to every instance. 

## Used technologies
 - [cloudinit using datasource NoCloud](https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html)
 - [proxmox](https://www.proxmox.com/de/)
 - [GNS3](https://github.com/GNS3/gns3-gui/releases)
 - [A GNS3 installation script](https://docs.gns3.com/docs/getting-started/installation/remote-server/)
 - A 10 year old VLAN able gigabit switch
 - MikroTik Router
 - ubuntu cloud image

# Realization
 - Assemble a bunch of old servers, wire them up and install proxmox on it
 - Enable [nested virtualization](https://pve.proxmox.com/wiki/Nested_Virtualization)
 - Network configuration (added nfs vlan, lab vlan and cluster vlan)
 - Put all the servers in one cluster
 - Set up vm with http server so that it can be used with nocloud-net
 - Create necessary cloudinit files and install scripts (see /var/www/html)
     + networking.sh => Some network adjustments and bug fixes
     + gns3-remote-install.sh => original GNS3 install script adjusted for my needs
 - Write script to automatically build VMs in proxmox
 - Add some dirty PHP with some features
 - Fix scripts until they work
 - Deploy all machines for my students

# Deployment procedures
 - Preliminary: The vm-create-scripts and the ubuntu cloud image are stored in a nfs that is connected to all proxmox nodes
 - run _./create.sh VMID_ N times on the server (n beeing the number of vms to run on that physical machine)
 - Start the VM
 - Get the keys from the MASTERNODE

# MASTERNODE
- Basically a HTTP server with all the preliminary files the VMs need to install GNS3 and OpenVPN
 - Debian GNU/Linux 10 Server with packages:
     + apt install apache2-utils apache2 php php-mysql libapache2-mod-php
 - For WebDAV we need SSL:
     + openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
 - apache2:
     + a2enmod ssl
     + a2enmod dav
     + a2enmod dav_fs
 - WebDAV activated for faster development
 - VM loads files used by cloudinit

# up.php
 - The user-data script calls the networking.sh script. When this script is finished it makes a POST request to the MASTERNODE submitting the ovpn configuration for the client.

# FAQ
## Can I copy paste this and start using it?
 - No, you'll have to adjust it to your infrastructre.  

## What do I have to do?
 - Plan and deploy your cluster (hardware, networking)
 - At least replace the following placeholders
     + MASTERNODE
     + ADD_YOUR_KEY_HERE
     + ADD_YOUR_PASSWOR_HERE
 - Set up vm with http and put all files in that folder
 - Prepary one GNS3 lab with images, but the hole image folder into a tar.gz and put in /var/www/html/images on the MASTERNODE. 

23.02.2021