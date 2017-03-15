#!/bin/bash

COMMAND="sh /home/joe/.config/herbstluftwm/panel.sh"
result="$(ps -ef | grep panel.sh | grep -v grep)"
#check to see if conky is running
if [ -z "$result" ]
then
    #if it is, then kill it
    herbstclient pad 0 20 0 0 0
    $COMMAND;
else
    #if its not, start it up
    herbstclient pad 0 0 0 0 0
    killall lemonbar
    killall panel.sh
    killall panel-hide.sh;

fi
exit 0
