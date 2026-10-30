#!/bin/bash

# Configuration
HISTORY_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-calc-history"
MAX_HISTORY=10
ROFI_THEME="$HOME/.config/rofi/launchers/type-1/style-4.rasi"

# Create history file if it doesn't exist
touch "$HISTORY_FILE"

# Function to add to history (Fixed to handle symbols like * safely)
add_to_history() {
    local expression="$1"
    local result="$2"
    local entry="${expression} = ${result}"
    
    # Remove old entry if it exists (using grep -F for safe string matching)
    if [ -f "$HISTORY_FILE" ]; then
        grep -vF "${expression} = " "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
        mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
    
    # Add new entry at the top
    echo "$entry" | cat - "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    
    # Keep only last MAX_HISTORY entries
    sed -i "$((MAX_HISTORY + 1)),\$d" "$HISTORY_FILE"
}

# Function to show history
show_history() {
    if [ -s "$HISTORY_FILE" ]; then
        cat "$HISTORY_FILE"
    fi
}

# Main calculator loop
while true; do
    # Show history and prompt for new calculation
    calc=$(show_history | rofi -dmenu -p "Calculator" -theme "$ROFI_THEME")
    
    # Exit if nothing selected
    [ -z "$calc" ] && break
    
    # Skip if it's a separator line
    if [[ "$calc" == "---"* ]]; then
        continue
    fi
    
    # If selected from history, extract the expression part.
    # We use %% to aggressively strip everything starting from the FIRST " = "
    # This fixes the "1+1 = 1+1 = true" loop issue.
    if [[ "$calc" == *" = "* ]]; then
        calc="${calc%% = *}"
    fi
    
    # Validate input
    if [[ "$calc" =~ [\;\&\|\`\$\(\)] ]]; then
        rofi -e "Invalid characters detected" -theme "$ROFI_THEME"
        continue
    fi
    
    # Calculate using qalc -t (terse mode) to get ONLY the result
    result=$(qalc -t "$calc" 2>/dev/null)
    exit_code=$?
    
    # Check if calculation was successful
    if [ $exit_code -ne 0 ] || [ -z "$result" ]; then
        rofi -e "Error: Invalid expression" -theme "$ROFI_THEME"
        continue
    fi
    
    # Add to history
    add_to_history "$calc" "$result"
    
    # Copy formatted equation to clipboard
    echo "$calc = $result" | wl-copy
    
    # Continue
    continue
done
