# File modification stuff

# SSH keys
find ~/.ssh/ ! -name '*.pub' -iname 'id*' -exec chmod 600 {} \;
