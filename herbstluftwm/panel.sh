#!/bin/bash

# todo: fontello icons

# disable path name expansion or * will be expanded in the line
# cmd=( $line )

if [ $(pgrep -cx lemonbar) -gt 0 ] ; then
	printf "%s\n" "The panel is already running." >&2
	exit 1
fi

# Format the Panel
fifo="/tmp/panel_fifo"
[ -e "$fifo" ] && rm "$fifo"
mkfifo "$fifo"

backlight() {
    light=" $(xbacklight | cut -d "." -f 1)"
    printf "%s\n" "backlight${light}"
}

processes() {
    steam="$(ps aux | grep steam | grep -v grep)"
    msg=""
    if [ -z "$steam" ]
    then
	msg="";
    else
	msg="%{A:steam -silent:}%{A}";
    fi
    deluge="$(ps aux | grep deluged | grep -v grep)"
    if [ -z "$deluge" ]
    then
	msg="$msg";
    else
	msg="$msg %{A:deluge:}%{A}";
    fi
    
    printf "%s\n" "processes${msg}"



}
music() {


    ans="$(ps aux | grep cmus | grep -v grep)"
    if [ -z "$ans" ]
    then
	cmusdata=""
	music=" - ";
    else
	cmusdata="$(cmus-remote -Q)"
	music="$(echo -e "$cmusdata"| grep "tag artist" | cut -d ' ' -f 3-) - $(cmus-remote -Q | grep "tag title" | cut -d ' ' -f 3-)";
    fi
    playStat="$(echo -e "$cmusdata" | grep status | cut -d " " -f 2)"
    if [ "$playStat" == "playing" ]
    then
    	playStat="";
    elif [ "$playStat" == "paused" ]
    then
    	playStat="";
    elif [ "$playStat" == "stopped" ]
    then
    	playStat="";
    fi

    
    if [ "$music" = " - " ]; then
    	music="";
    else
    	dur="$(echo -e "$cmusdata"| grep duration | cut -d " " -f 2)"
    	pos="$(echo -e "$cmusdata"| grep position | cut -d " " -f 2)"

	durformat="$(date -u -d@${dur} +"%-M:%S")"
 	posformat="$(date -u -d@${pos} +"%-M:%S")"
    	div="$(bc <<< "scale=2; $pos / $dur")"
    	div=${div:1}

    	if [ "$div" == "" ]
    	then
    	    div="00";
    	fi
	div="$posformat / $durformat"
    	if [ "$playStat" == "" ]
    	then
    	    music="$music | $playStat | ";
    	else
    	    music="$music | $playStat | $div | ";
    	fi
    fi

    printf "%s\n" "music%{F#FFFFFF}${music}"


}

volume() {
   WHITE="%{F#FFFFFFFF}"
    mixerdata="$(amixer sget Master)"

    vol="$(echo -e "$mixerdata" | sed -n '6p' | cut -d " " -f 7)"
    volmute="$(echo -e "$mixerdata" | sed -n '6p' | cut -d " " -f 8 | grep off)"
        vol=${vol:1:-2}
	volcolor="%{F#ffffffff}"
    if [ "$volmute" != "" ]
    then
       volcolor="%{F#C75646}";
    fi 
    if [ "$vol" -gt 45 ]
    then
	vol="$volcolor$WHITE $vol";
    elif [ "$vol" -gt 15 ]
    then
	vol="$volcolor$WHITE $vol";
    else
	vol="$volcolor$WHITE $vol";
    fi

    printf "%s\n" "volume${vol}"
}

monitor() {

	monitors="$(herbstclient tag_status)"
	string=""
	for screen in $monitors
	do

	    if [ "${screen:0:1}" = '#' ]; then
		string="$string %{F#FFFFFF} ${screen:1}";
	    fi
	    if [ "${screen:0:1}" = ':' ]; then
		string="$string %{F#AAAAAA} ${screen:1}";
	    fi
	    if [ "${screen:0:1}" = '.' ]; then
		string="$string %{F#222222} ${screen:1}";
	    fi
	done

	printf "%s\n" "monitor${string}"

}

weatherNow() {

    weather="$(weather 02142)"
	if [ -z "$weather" ]
	then
	    weather="";
	else
	    weather=${weather::-1}"°F"
	    weather="|  $weather"
	fi

	printf "%s\n" "weather%{F#FFFFFFFF}${weather}"
}

temperature() {
    temp=$(sensors -u | grep temp1_input | sed -n 2p | awk  '{print $2}')
	temp=${temp::-4}
	COL=""
	if [ "$temp" -lt 70 ]
	then
	    COL="%{F#CDEE69}";
	elif [ "$temp" -lt 86 ]
	then
	    COL="%{F#D0B03C}";
	elif [ "$temp" -lt 100 ]
	then
	    COL="%{F#E09690}";
	else
	    COL="%{F#C75646}";
	fi
	temp="$COL %{F#FFFFFF}$temp°C"

	printf "%s\n" "temperature${temp}"


}

usage() {
    mem=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }' | cut -d "." -f 1)
	mem="RAM "${mem}"%"
	cpu=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}'  )
	cpu=$(echo $cpu | tr "." "\n")
	for num in $cpu
	do
	    cpu="CPU $num%"
	    break
	done

	usage="$cpu $mem"
	printf "%s\n" "usage${usage}"

}

battery() {
    stat=""
	acpidata="$(acpi)"
	checkup="$(echo -e "$acpidata" | grep Charging)"
	checkdown="$(echo -e "$acpidata" | grep Discharging)"
	if [ "$checkup" != "" ]
	then
	    stat="";
	elif [ "$checkdown" != "" ]
	then
	    stat="";
	fi
	power=$(cat /sys/class/power_supply/BAT0/capacity)
	time=$(cut -d "%" -f 2 <<< $(acpi))
	checkTime="$(acpi | grep "charging at zero rate")"
	if [ -z "$checkTime" ]
	then
	    if [ "$checkTime" == ", until charged" ]
	    then
		time=" ";
	    else
		time=" "${time:3:4}" ";
	    fi
	else
	    time=" ";
	fi
	if [ "$power" -gt 90 ]
	then
	    power="%{F#8EB33B}%{F#ffffff} $power%";
	elif [ "$power" -gt 65 ]
	then
	    power="%{F#cdee69}%{F#ffffff} $power%";
	elif [ "$power" -gt 35 ]
	then
	    power="%{F#FFE377}%{F#FFFFFFFF} $power%";
	elif [ "$power" -gt 15 ]
	then
	    power="%{F#D0B03C}%{F#FFFFFFFF} $power%";
	else
	    power="%{F#C75646}%{F#FFFFFFFF} $power%";
	fi
	power="$power$time$stat"

	printf "%s\n" "battery${power}"
}

day() {
    date="$(date +"%A, %B %e")"
    printf "%s\n" "day${date}"

}

clock() {
    time="$(date +"%H:%M")"
    printf "%s\n" "clock${time}"
}

wifi(){
    color="%{F#ffffff}"
     data="$(iwconfig wlp3s0)"
     essid="$(echo -e "$data" |grep ESSID | cut -d " " -f 8)"
     strength="$(echo -e "$data" | grep Signal | cut -d " " -f 12)"
     strength="${strength:8}"
     strength="$(echo "scale=2; $strength" | bc)"
     if [ "$strength" == "1.00" ]; then
	 strength=".99"
     fi
     strength=" ${strength:1}%"
      check="$( grep off/any)"
      if [ "$essid" == "ESSID:off/any" ]; then
      	  essid=""
	  color="%{F#aaaaaa}"
	  strength=""
      else
      	  essid="${essid:7}"
      fi
      printf "%s\n" "wifi${color}%{F#FFFFFF} ${essid}${strength}"
}



while :; do music; sleep 1s; done > "$fifo" &
while :; do volume; sleep 1s; done > "$fifo" &
while :; do monitor; sleep 1s; done > "$fifo" &
while :; do temperature; sleep 1s; done > "$fifo" &
while :; do weatherNow; sleep 1s; done > "$fifo" &
while :; do usage; sleep 1s; done > "$fifo" &
while :; do battery; sleep 1s; done > "$fifo" &
while :; do day; sleep 1s; done > "$fifo" &
while :; do clock; sleep 1s; done > "$fifo" &
while :; do wifi; sleep 1s; done > "$fifo" &
while :; do backlight; sleep 1s; done > "$fifo" &
while :; do processes; sleep 1s; done > "$fifo" &



while read -r line ; do

    case $line in
        music*)
            music="${line:5}"
            ;;
        volume*)
            volume="${line:6}"
            ;;
        monitor*)
            monitor="${line:7}"
            ;;
        temperature*)
            temperature="${line:11}"
            ;;
	weather*)
            weather="${line:7}"
            ;;
        usage*)
            usage="${line:5}"
            ;;
        battery*)
            battery="${line:7}"
            ;;
	day*)
            day="${line:3}"
            ;;
	clock*)
            clock="${line:5}"
            ;;
	wifi*)
	    wifi="${line:4}"
	    ;;
	backlight*)
	    backlight="${line:9}"
	    ;;
	processes*)
	    processes="${line:9}"
	    ;;
    esac
     if  pgrep -x "dmenu_run" > /dev/null
     then
	 sleep .04
     	echo "%{B#00000000}%{F#00000000} ";
     else
	 echo  "%{B#E6282333}%{l} ${music} ${volume} | ${backlight} | ${processes} %{c}${monitor} %{r}%{O50}${weather} | ${wifi} | ${temperature} | ${usage} | ${battery} | ${day} | ${clock}%{O10}";
     fi


done < "$fifo" | lemonbar -B "#e6282333" -f "Source Code Pro:size=7" -f "FontAwesome-8" -f "-wuncon-siji-medium-r-normal--10-100-75-75-c-80-iso10646-1" -g 1600x20 -o -3 | bash; exit
