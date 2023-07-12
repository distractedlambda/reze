FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
    file://64kb-pages.cfg \
    file://multicore-scheduler.cfg \
    file://no-32bit.cfg \
    file://no-amateur-radio.cfg \
    file://no-appletalk.cfg \
    file://no-ata.cfg \
    file://no-atm.cfg \
    file://no-batman.cfg \
    file://no-bluetooth.cfg \
    file://no-btrfs.cfg \
    file://no-can-bus.cfg \
    file://no-ceph-fs.cfg \
    file://no-drbd.cfg \
    file://no-ecrypt.cfg \
    file://no-ethernet-bridging.cfg \
    file://no-f2fs.cfg \
    file://no-fuse.cfg \
    file://no-gfs2.cfg \
    file://no-hfs.cfg \
    file://no-iio.cfg \
    file://no-iso9660-fs.cfg \
    file://no-jffs2.cfg \
    file://no-jfs.cfg \
    file://no-kaiser.cfg \
    file://no-kaslr.cfg \
    file://no-loopback-block-device.cfg \
    file://no-mtd.cfg \
    file://no-namespaces.cfg \
    file://no-nbd.cfg \
    file://no-nfc.cfg \
    file://no-nfs-client.cfg \
    file://no-nfs-server.cfg \
    file://no-nilfs2.cfg \
    file://no-ntfs.cfg \
    file://no-nvme.cfg \
    file://no-ocfs2.cfg \
    file://no-openvswitch.cfg \
    file://no-overlayfs.cfg \
    file://no-packet-generator.cfg \
    file://no-plan9-resource-sharing.cfg \
    file://no-raid.cfg \
    file://no-ramdisk.cfg \
    file://no-reiserfs.cfg \
    file://no-remote-controllers.cfg \
    file://no-rtc.cfg \
    file://no-scsi.cfg \
    file://no-security-models.cfg \
    file://no-smb-client.cfg \
    file://no-smb-server.cfg \
    file://no-spectre-mitigation.cfg \
    file://no-squashfs.cfg \
    file://no-stack-protector.cfg \
    file://no-swap.cfg \
    file://no-udf-fs.cfg \
    file://no-usb-network-adapters.cfg \
    file://no-virtualization.cfg \
    file://no-wifi.cfg \
    file://no-xfs.cfg \
    file://no-zram.cfg \
    file://quadcore.cfg \
    file://schedutil-governor.cfg \
    file://trim-unused-ksyms.cfg \
    file://tune-cortexa72.cfg \
    file://zstd-module-compression.cfg \
    "
