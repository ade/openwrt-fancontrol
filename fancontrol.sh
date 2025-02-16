#!/bin/sh

# OpenWRT fan control using RickStep and Chadster766's logic

# SLEEP_DURATION and CPU_TEMP_CHECK need to be multiples of each other
SLEEP_DURATION=5
CPU_TEMP_CHECK=20
DEFAULT_SPEED=225                  

# DON'T MESS WITH THESE
VERBOSE=0
LAST_FAN_SPEED=$DEFAULT_SPEED                  
ELAPSED_TIME=0 
CPU_TEMP=0
RAM_TEMP=0
WIFI_TEMP=0

# determine verbose mode
if [ ! -z "$1" ]; then
    VERBOSE=1
fi

# determine fan controller
if [ -d /sys/devices/pwm_fan ]; then
    FAN_CTRL=/sys/devices/pwm_fan/hwmon/hwmon0/pwm1
elif [ -d /sys/devices/platform/pwm_fan ]; then
    FAN_CTRL=/sys/devices/platform/pwm_fan/hwmon/hwmon0/pwm1
else
    exit 0
fi

# retrieve new cpu, ram, and wifi temps
get_temps() {
    CPU_TEMP=`cut -c1-2 /sys/class/hwmon/hwmon2/temp1_input` 
    RAM_TEMP=`cut -c1-2 /sys/class/hwmon/hwmon1/temp1_input` 
    WIFI_TEMP=`cut -c1-2 /sys/class/hwmon/hwmon1/temp2_input`
}

# use this to make setting the fan a bit easier
#     set_fan WHAT VALUE
set_fan() {
    LAST_FAN_SPEED=`cat ${FAN_CTRL}`

    if [ $LAST_FAN_SPEED -ne $2 ]; then
        if [ $VERBOSE == 1 ]; then
            echo "setting fan to ${2} (${1}) ${FAN_CTRL}"
        fi

        # write the new speed to the fan controller
        echo $2 > ${FAN_CTRL}
    else
        if [ $VERBOSE == 1 ]; then
            echo "keeping fan speed at ${LAST_FAN_SPEED}"
        fi
    fi
}

# floating-point greater-than-or-equals-to using awk 'cause ash doesn't
# like floats. instead of this:
#     if [ $VALUE_1 >= $VALUE_2 ];
# use this:
#     if [ $(fge $VALUE_1 $VALUE_2) == 1 ];
float_ge() {
    awk -v n1=$1 -v n2=$2 "BEGIN { if ( n1 >= n2 ) exit 1; exit 0; }"
    echo $?
}          

# check for load averages above 1.0
check_load() {
    # loop over each load value (1 min, 5 min, 15 min)
    for LOAD in `cat /proc/loadavg | cut -d " " -f1,2,3`; do
        if [ $VERBOSE == 1 ]; then
            echo "Checking Load ${LOAD}"
        fi
    done
}

check_temp_change() {
    TEMP_CHANGE=$(($3 - $2));

    if [ $VERBOSE == 1 ]; then
        echo "${1} original temp: ${2} | new temp: ${3} | change: ${TEMP_CHANGE}"
    fi
}

# set fan speeds based on CPU temperatures
check_cpu_temp() {
    if [ $VERBOSE == 1 ] ; then
        echo "Current CPU Temp ${CPU_TEMP}"
    fi

    if [ $CPU_TEMP -ge 98 ]; then
        set_fan CPU 255
    elif [ $(float_ge $CPU_TEMP 95.0) == 1 ]; then
        set_fan CPU 225
    elif [ $CPU_TEMP -ge 90 ]; then
        set_fan CPU 190
    elif [ $CPU_TEMP -ge 85 ]; then
        if [ $VERBOSE == 1 ]; then
            echo "Waiting to modify (85-90)..."
        fi
    else
        set_fan CPU 0
    fi
}

# start the fan initially to $DEFAULT_SPEED
set_fan START $DEFAULT_SPEED

# and get the initial system temps
get_temps

# the main program loop:
# - look at load averages every $SLEEP_DURATION seconds
# - look at temperature deltas every $SLEEP_DURATION seconds
# - look at raw cpu temp every $CPU_TEMP_CHECK seconds
while true ; do

    # save the previous temperatures                                    
    LAST_CPU_TEMP=$CPU_TEMP                                            
    LAST_RAM_TEMP=$RAM_TEMP                                                      
    LAST_WIFI_TEMP=$WIFI_TEMP                                                 

    # and re-read the current temperatures
    get_temps 

    # check the load averages
    check_load

    # check to see if the cpu, ram, or wifi temps have spiked
    check_temp_change CPU $CPU_TEMP $LAST_CPU_TEMP
    check_temp_change RAM $RAM_TEMP $LAST_RAM_TEMP
    check_temp_change WIFI $WIFI_TEMP $LAST_WIFI_TEMP

    # check the raw CPU temps every $CPU_TEMP_CHECK seconds...
    if [ $(( $ELAPSED_TIME % $CPU_TEMP_CHECK )) == 0 ]; then
        check_cpu_temp
    fi

    # wait $SLEEP_DURATION seconds and do this again
    if [ $VERBOSE == 1 ]; then
        echo "waiting ${SLEEP_DURATION} seconds..."
        echo
    fi

    sleep $SLEEP_DURATION;

    ELAPSED_TIME=$(($ELAPSED_TIME + $SLEEP_DURATION))
done
