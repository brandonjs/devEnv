#!/bin/bash

if [ ! -f "${HOME}/bin/repo" ] ;then
    curl http://android.git.kernel.org/repo > ~/bin/repo
fi
${HOME}/bin/repo init -u git://git-android.quicinc.com/platform/manifest.git -b gingerbread
