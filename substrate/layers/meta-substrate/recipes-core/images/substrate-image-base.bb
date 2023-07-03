inherit core-image

inherit image-buildinfo

inherit extrausers
SUBSTRATE_PASSWD = "\$6\$aDgSTGFIXC5U6vL4\$U2q8xiBdYNrSJOPgYzSOaMTqTFRXuWv/9IGslq5E5Akc4wdMSsCpwFxnrXomV2ziJuXGekPxbPyCsv9zJQYLI1"
EXTRA_USERS_PARAMS = "\
    useradd -mp '${SUBSTRATE_PASSWD}' substrate; \
    usermod -p '${SUBSTRATE_PASSWD}' root; \
    "
