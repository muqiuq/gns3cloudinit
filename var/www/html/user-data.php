#cloud-config
<?php
$skipGNS3 = false;
$ip_parts = explode(".", $_SERVER["REMOTE_ADDR"]);
$name = $ip_parts[count($ip_parts)-1]; ?>
hostname: <?php echo "gns3lab-" . $name; ?>

manage_etc_hosts: true
password: ADD_YOUR_PASSWORD_HERE (use mkpasswd)
chpasswd:
  expire: False
user: user
package_upgrade: true
ssh_authorized_keys:
  - ADD_YOUR_KEY_HERE
timezone: Europe/Zurich

runcmd:
  - touch /tmp/GNS3LAB
  - curl http://MASTERHOST/networking.sh > /tmp/networking.sh
  - bash /tmp/networking.sh
  - touch /etc/cloud/cloud-init.disabled
<?php if(!$skipGNS3): ?>
  - mkdir /opt/gns3install
  - curl http://MASTERHOST/gns3-remote-install.sh > /opt/gns3install/gns3-remote-install.sh
  - bash /opt/gns3install/gns3-remote-install.sh
<?php endif; ?>
final_message: "The system is finally up, after $UPTIME seconds"
packages:
 - vim
 - net-tools
 - htop
 - tmux
 - bridge-utils
 - wget
 - ifupdown
 - isc-dhcp-server
 - openvpn
 - uuid
 - dnsutils
power_state:
  mode: reboot
