#! /bin/bash
actions="logout
shutdown
reboot
sleep
hibernate"
result=$(echo "$actions" | dmenu   -fn "Source Code Pro-9" -l 10 -y 30 -w 100 -x 1500 -sb "#ffffff" -nb "#383C4A" -sf "#383C4A")
cmd=$(echo "$result" | cut -d' ' -f2-)
[ -n "$cmd" ] && eval setsid setsid "$cmd"
