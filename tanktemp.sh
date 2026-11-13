
#!/bin/bash

# DS18B20 temperature reader for Raspberry Pi
# Usage:
#   ./read-tank-temperature.sh          Display temperature
#   ./read-tank-temperature.sh --zabbix Return numeric value only

W1_DEVICE="${W1_DEVICE:-}"
W1_BASE="/sys/bus/w1/devices"

# Automatically find the first DS18B20 sensor if not specified
if [[ -z "$W1_DEVICE" ]]; then
    for device in "$W1_BASE"/28-*; do
        if [[ -f "$device/w1_slave" ]]; then
            W1_DEVICE="$device"
            break
        fi
    done
fi

if [[ -z "$W1_DEVICE" || ! -f "$W1_DEVICE/w1_slave" ]]; then
    echo "ERROR: DS18B20 sensor not found" >&2
    exit 1
fi

# Read sensor data
DATA=$(cat "$W1_DEVICE/w1_slave")

# Check sensor CRC
if ! grep -q "YES" <<< "$DATA"; then
    echo "ERROR: Sensor CRC check failed" >&2
    exit 1
fi

# Extract temperature in millidegrees Celsius
TEMP_RAW=$(grep -o 't=[-0-9]*' <<< "$DATA" | tail -n1 | cut -d= -f2)

if [[ ! "$TEMP_RAW" =~ ^-?[0-9]+$ ]]; then
    echo "ERROR: Unable to read temperature" >&2
    exit 1
fi

# Convert to Celsius with two decimal places
TEMP=$(awk "BEGIN { printf \"%.2f\", $TEMP_RAW / 1000 }")

if [[ "$1" == "--zabbix" ]]; then
    # Zabbix expects a numeric value only
    echo "$TEMP"
else
    echo "Fish tank temperature: ${TEMP} °C"
    echo "Sensor: $(basename "$W1_DEVICE")"
fi

