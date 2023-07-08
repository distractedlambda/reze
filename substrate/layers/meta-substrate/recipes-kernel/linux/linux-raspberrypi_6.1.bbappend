FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
    file://multicore-scheduler.cfg \
    file://no-32bit.cfg \
    file://no-kaiser.cfg \
    file://no-kaslr.cfg \
    file://no-namespaces.cfg \
    file://no-security-models.cfg \
    file://no-spectre-mitigation.cfg \
    file://no-stack-protector.cfg \
    file://no-swap.cfg \
    file://no-virtualization.cfg \
    file://quadcore.cfg \
    file://schedutil-governor.cfg \
    file://tune-cortexa72.cfg \
    file://zstd-module-compression.cfg \
    "
