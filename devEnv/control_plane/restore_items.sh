#!/bin/bash

set -x
exec > /tmp/control_plane_restore_items.log 2>&1
[ -f ~/control_plane/stay_restore.scpt ] && osascript ~/control_plane/stay_restore.scpt
[ -f ~/geeklets/gather.scpt ] && osascript ~/geeklets/gather.scpt 

exit 0
