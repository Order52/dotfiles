#!/bin/bash

sleep 5
/usr/bin/ludusavi backup --force

sleep 10

# Execute the original commands
dualsensectl player-leds 0
dualsensectl lightbar off
dualsensectl trigger right weapon 3 7 6
dualsensectl trigger left feedback 4 6


