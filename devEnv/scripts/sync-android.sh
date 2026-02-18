#!/bin/bash
if [ ! -f "${HOME}/bin/repo" ] ;then
    curl http://android.git.kernel.org/repo > ~/bin/repo
fi

${HOME}/bin/repo sync --jobs=20 $* 
