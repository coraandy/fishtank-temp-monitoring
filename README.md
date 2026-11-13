# Fish Tank Temperature Monitoring

A Bash script for reading a DS18B20 temperature sensor on a Raspberry Pi. It can
print a human-readable temperature or return a numeric value for Zabbix Agent 2.

## Hardware

- Raspberry Pi with 1-Wire support enabled
- DS18B20 temperature sensor
- 4.7 kΩ pull-up resistor

For a three-wire sensor, connect VDD to 3.3 V, GND to a Pi ground pin, and DATA
to the configured 1-Wire GPIO (commonly BCM GPIO 4, physical pin 7). Connect
the 4.7 kΩ resistor between DATA and 3.3 V. Enable the Pi's 1-Wire interface
and confirm the sensor appears under `/sys/bus/w1/devices/`.

## Install and run

Keep the script executable and run it with Bash:

```sh
chmod +x /home/andrea/SCRIPTS/fishtank/tanktemp.sh
/bin/bash /home/andrea/SCRIPTS/fishtank/tanktemp.sh
```

By default, the script selects the first DS18B20 device it finds. To select a
specific sensor, set `W1_DEVICE` to its device directory:

```sh
W1_DEVICE=/sys/bus/w1/devices/28-000000bab6d6 \
  /bin/bash /home/andrea/SCRIPTS/fishtank/tanktemp.sh
```

Use `--zabbix` to print only the numeric Celsius value:

```sh
/bin/bash /home/andrea/SCRIPTS/fishtank/tanktemp.sh --zabbix
```

## Zabbix Agent 2

Add a user parameter to an Agent 2 configuration file (for example, in
`/etc/zabbix/zabbix_agent2.d/`):

```ini
UserParameter=fish.tank.temperature,/bin/bash /home/andrea/SCRIPTS/fishtank/tanktemp.sh --zabbix
```

The explicit `/bin/bash` is important: Zabbix may execute user parameters
through `/bin/sh`, which does not support the Bash `[[ ... ]]` syntax used by
this script.

Restart the agent and test the key:

```sh
sudo systemctl restart zabbix-agent2
zabbix_agent2 -t fish.tank.temperature
```

The Agent 2 service account must be able to read the sensor's `w1_slave` file.
If the test reports that the sensor is missing, verify sensor availability and
permissions, then test the script as the agent user:

```sh
sudo -u zabbix /bin/bash /home/andrea/SCRIPTS/fishtank/tanktemp.sh --zabbix
```
