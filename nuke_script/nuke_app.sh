#!/bin/bash

echo "🧨 Welcome to the Nuke Script"
echo "-----------------------------"

# App name input
read -p "Enter the Application Name (fuzzy, e.g., Zoom): " APP_NAME_INPUT

# Smart search
echo ""
echo "🔍 Searching for matching apps in /Applications..."
MATCHES=($(ls /Applications | grep -i "$APP_NAME_INPUT"))

if [ ${#MATCHES[@]} -eq 0 ]; then
  echo "❌ No matches found. Aborting."
  exit 1
fi

echo ""
echo "Is it one of these?"
for i in "${!MATCHES[@]}"; do
  printf "  (%s) %s\n" "$(printf "\x$(printf %x $((97 + $i)))")" "${MATCHES[$i]}"
done

read -p "Choose a letter: " SELECTION

INDEX=$(printf "%d" "'$SELECTION'")
INDEX=$((INDEX - 97))  # 'a' -> 0, 'b' -> 1, etc.

SELECTED_APP="${MATCHES[$INDEX]}"

if [ -z "$SELECTED_APP" ]; then
  echo "❌ Invalid selection. Aborting."
  exit 1
fi

# Optional: suggest process keyword
DEFAULT_KEYWORD=$(echo "$APP_NAME_INPUT" | tr '[:upper:]' '[:lower:]')

echo ""
read -p "Enter the process keyword (e.g., adobe, zoom) or type '?' for help: " PROCESS_KEYWORD

if [[ "$PROCESS_KEYWORD" == "?" ]]; then
  echo ""
  echo "🧠 Attempting to identify running processes related to: $APP_NAME_INPUT"
  echo "🔎 Running: ps aux | grep -i \"$APP_NAME_INPUT\""
  echo ""
  ps aux | grep -i "$APP_NAME_INPUT" | grep -v grep

  echo ""
  echo "👀 Look through the above lines to find the common process keyword (e.g., adobe, zoom)"
  read -p "Now enter the process keyword to use [default: $DEFAULT_KEYWORD]: " PROCESS_KEYWORD

  if [[ -z "$PROCESS_KEYWORD" ]]; then
    PROCESS_KEYWORD="$DEFAULT_KEYWORD"
    echo "ℹ️ Using default guess: $PROCESS_KEYWORD"
  fi
fi

# Dry run?
read -p "Dry run only? (y/n): " DRY_MODE
if [[ "$DRY_MODE" == "y" ]]; then
  IS_DRY=true
  echo "🧪 Dry run mode activated — no actions will be performed."
else
  IS_DRY=false
fi

# Confirm nuke
echo ""
echo "⚠️ This will permanently delete ${SELECTED_APP} and all related files."
echo "To proceed, type: permanently nuke"
read -p "> " CONFIRM
if [[ "$CONFIRM" != "permanently nuke" ]]; then
  echo "❌ Confirmation failed. Aborting."
  exit 1
fi

# DRY MODE command handler
run_cmd() {
  if $IS_DRY; then
    echo "👉 Would run: $*"
  else
    eval "$@"
  fi
}

APP_PATH="/Applications/$SELECTED_APP"

echo ""
echo "🔴 Killing processes matching \"$PROCESS_KEYWORD\"..."
run_cmd "sudo pkill -f \"$PROCESS_KEYWORD\""

echo ""
echo "🗑 Deleting $SELECTED_APP..."
run_cmd "sudo rm -rf \"$APP_PATH\""
run_cmd "sudo rm -rf /Applications/Utilities/\"$SELECTED_APP\""
run_cmd "sudo rm -rf /Applications/\"$SELECTED_APP\"*"

echo ""
echo "🧹 Removing User Library files..."
run_cmd "rm -rf ~/Library/Application\\ Support/\"$PROCESS_KEYWORD\""
run_cmd "rm -rf ~/Library/Preferences/com.\"$PROCESS_KEYWORD\".*"
run_cmd "rm -rf ~/Library/Caches/\"$PROCESS_KEYWORD\""
run_cmd "rm -rf ~/Library/Logs/\"$PROCESS_KEYWORD\""
run_cmd "rm -rf ~/Library/LaunchAgents/com.\"$PROCESS_KEYWORD\".*"

echo ""
echo "🧹 Removing System Library files..."
run_cmd "sudo rm -rf /Library/Application\\ Support/\"$PROCESS_KEYWORD\""
run_cmd "sudo rm -rf /Library/Preferences/com.\"$PROCESS_KEYWORD\".*"
run_cmd "sudo rm -rf /Library/LaunchAgents/com.\"$PROCESS_KEYWORD\".*"
run_cmd "sudo rm -rf /Library/LaunchDaemons/com.\"$PROCESS_KEYWORD\".*"

echo ""
echo "🔒 Disabling remaining launch agents..."
run_cmd "launchctl bootout gui/\$(id -u) ~/Library/LaunchAgents/com.\"$PROCESS_KEYWORD\".* 2>/dev/null"
run_cmd "sudo launchctl bootout system /Library/LaunchDaemons/com.\"$PROCESS_KEYWORD\".* 2>/dev/null"

echo ""
echo "🔍 Final Process Check:"
run_cmd "ps aux | grep -i \"$PROCESS_KEYWORD\" | grep -v grep"

echo ""
if $IS_DRY; then
  echo "✅ Dry run complete. No changes made."
else
  echo "✅ $SELECTED_APP has been nuked from orbit."
fi