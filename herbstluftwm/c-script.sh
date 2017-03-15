#!/bin/bash

#command to start conky - change to current conky startup command
CONKYCOMMAND="conky-notes"
result="$(ps -ef | grep conky | grep -v grep)"
#check to see if conky is running
if [ -z "$result" ]
then
    #if it is, then kill it

    $CONKYCOMMAND;
else
    #if its not, start it up
    killall conky;

fi
exit 0
