#!/usr/bin/env bash
#
# Visible LCD Pixel Refresher (X11)
# Uses xrandr brightness flashing only
# No dependencies except bash + xrandr
#

#############################
# USER SETTINGS
#############################

FLASHES=50         # number of flashes
LOW_BRIGHT=0.1     # how dark screen goes (0.0–1.0)
HIGH_BRIGHT=10   # how bright screen goes (>1.0 allowed)
DELAY_MS=1000       # delay between flashes in milliseconds

#############################
# INTERNAL FUNCTIONS
#############################

sleep_ms() {
    perl -e "select(undef,undef,undef,$1/1000)";
}

# determine display output
OUTPUT=$(xrandr --query | awk '/ connected/ {print $1; exit}')

if [ -z "$OUTPUT" ]; then
    echo "Error: could not determine display output from xrandr"
    exit 1
fi

# read original brightness
ORIG=$(xrandr --verbose | awk '/Brightness:/ {print $2; exit}')

if [ -z "$ORIG" ]; then
    ORIG=1.0
fi

echo "Display detected: $OUTPUT"
echo "Original brightness: $ORIG"
echo "Beginning $FLASHES flashes..."

#####################################
# FLASH LOOP
#####################################

for ((i=1; i<=FLASHES; i++)); do
    # Dim
    xrandr --output "$OUTPUT" --brightness "$LOW_BRIGHT" >/dev/null 2>&1
    sleep_ms "$DELAY_MS"

    # Super bright
    xrandr --output "$OUTPUT" --brightness "$HIGH_BRIGHT" >/dev/null 2>&1
    sleep_ms "$DELAY_MS"
done

#####################################
# RESTORE ORIGINAL BRIGHTNESS
#####################################

xrandr --output "$OUTPUT" --brightness "$ORIG" >/dev/null 2>&1

echo "Done. Brightness restored."

