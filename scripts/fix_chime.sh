#!/bin/bash

killall "Amazon Chime"
pushd /Applications/Amazon\ Chime.app/Contents/Resources/Base.lproj/ >/dev/null 2>&1
mv MeetingFeedbackWindowController.nib MeetingFeedbackWindowController.nib.old
touch MeetingFeedbackWindowController.nib
popd >/dev/null 2>&1
open /Applications/Amazon\ Chime.app
