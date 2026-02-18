#!/usr/local/bin/bash -e

HOSTNAME="bcd074629c51"
PHYSICAL_DRIVE_PATH="/System/Volumes/Data/mount/tm/"
SPARSEBUNDLE_NAME="${HOSTNAME}.sparsebundle"
SPARSEBUNDLE_PATH="/System/Volumes/Data/mount/tm/${SPARSEBUNDLE_NAME}"
SPARSEBUNDLE_MOUNT_PATH="/Volumes/Backups of ${HOSTNAME}"

# Check existing states
if [ -e "$SPARSEBUNDLE_MOUNT_PATH" ]; then
    echo "Already mounted."
    exit 0    
fi

if [ ! -e "$PHYSICAL_DRIVE_PATH" ]; then
    echo "Physical drive not attached"
    exit 0
fi

if [ ! -e "$SPARSEBUNDLE_PATH" ]; then
    echo "Virtual drive not found on physical drive"
    exit 1
fi

# The mount command uses security find-generic-password
# to get the password from the keychain store
MOUNT_PASSWORD=$(security find-generic-password -w -D "disk image password" -l ${SPARSEBUNDLE_NAME})
printf $MOUNT_PASSWORD | hdiutil attach -stdinpass "$SPARSEBUNDLE_PATH"

