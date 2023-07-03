inherit core-image

inherit image-buildinfo

inherit extrausers
SUBSTRATE_PASSWD = "\$6\$aDgSTGFIXC5U6vL4\$U2q8xiBdYNrSJOPgYzSOaMTqTFRXuWv/9IGslq5E5Akc4wdMSsCpwFxnrXomV2ziJuXGekPxbPyCsv9zJQYLI1"
EXTRA_USERS_PARAMS = "\
    useradd -m -G video -p '${SUBSTRATE_PASSWD}' substrate; \
    "

# TODO: integrate these somehow...
#   DISABLE_OVERSCAN = "1"
#   DISABLE_SPLASH = "1"
#   BOOT_DELAY = "0"
#   BOOT_DELAY_MS = "0"
#   DISABLE_RPI_BOOT_LOGO = "1"
#   RPI_EXTRA_CONFIG = "\
#       hdmi_enable_4kp60=1\n \
#       arm_boost=1\n \
#       "
