#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Please supply QMID"
    exit 1
fi

SMBIOS1=`echo "ds=nocloud-net;s=http://MASTERHOST:80/" | base64`

QMID=$1

qm create $QMID --cores 6 --acpi yes --kvm yes --memory 8192 --name gns3lab-$QMID --net0 model=virtio,bridge=vmbr2 --onboot 1 --serial0 socket --cpu cputype=host --sockets 1 --scsihw virtio-scsi-pci --smbios1 base64=1,serial=$SMBIOS1

qm importdisk $QMID /mnt/pve/nfs/utils/focal-server-cloudimg-amd64.img local-zfs
qm set $QMID --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-$QMID-disk-0
qm resize $QMID scsi0 +30G
qm set $QMID --boot c --bootdisk scsi0
