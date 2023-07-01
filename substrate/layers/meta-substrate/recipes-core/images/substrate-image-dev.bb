require substrate-image-minimal.bb

IMAGE_FEATURES += "\
    bash-completion-pkgs \
    ssh-server-openssh \
    "

IMAGE_INSTALL += "\
    kmscube \
    rsync \
    "

IMAGE_PREPROCESS_COMMAND += "substrate_prepopulate_public_ssh_key; "

fakeroot substrate_prepopulate_public_ssh_key () {
    ssh_dir="${IMAGE_ROOTFS}/home/substrate/.ssh"

    mkdir "${ssh_dir}"

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO2aa+jhJMF68MoxK6DvjA06WEWYOwHTun6BnlUQRvnO" > "${ssh_dir}/authorized_keys"

    chmod 700 "${ssh_dir}"
    chmod 640 "${ssh_dir}/authorized_keys"
    chown -R substrate:substrate "${ssh_dir}"
}
