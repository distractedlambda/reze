IMAGE_FEATURES += "hwcodecs"

IMAGE_INSTALL = "\
    mesa \
    packagegroup-core-boot \
    "

inherit core-image

inherit image-buildinfo

inherit extrausers
EXTRA_USERS_PARAMS = "useradd -m substrate;"
