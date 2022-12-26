# openwrt-fancontrol (fork)

Fan control script for OpenWRT on WRT1900ACv1

CPU = Marvell MV78230 (1.2 GHz, 2 Cores) Armada XP (Junction Temperature 105c)

Lets the CPU run to 90c before starting the fan in a low setting. 85-90c is a hysterisis period and won't enable/disable the fan. Reaching 85c again will disable the fan. Highest RPMs apply at 95 and 98c.

I've found that the (stock) fan does not spin up at all on PWM setting below 190 at least on my unit, so thats the lowest one used.

Tested with OpenWrt 22.03.2

####To use it:

* Download the new fan controller, save it to  /etc/, and make it executable.
```
wget --no-check-certificate https://raw.githubusercontent.com/ade/openwrt-fancontrol/master/fancontrol.sh -O /etc/fancontrol.sh
chmod +x /etc/fancontrol.sh
```

* Test it to make sure that it runs correctly.
```
/etc/fancontrol.sh verbose
```

* Let it run in the background to keep your router cool.
```
/etc/fancontrol.sh &
```

####Disable the orginal fan controller.
*	Remove or comment out this line from /etc/crontabs/root (In LuCI, it's System > Scheduled Tasks)
```
 */5 * * * * /sbin/fan_ctrl.sh
```

####Optional
* Have this run on boot.
* Add this to /etc/rc.local (In LuCI, it's System > Startup)
```
/etc/fancontrol.sh &
```
