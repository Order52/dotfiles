#!/bin/bash

while true; do
    pactl set-source-volume alsa_input.usb-GeneralPlus_USB_Audio_Device-00.mono-fallback 60%
    sleep 3
done

