#!/bin/bash

# This will be a script to completely reorganize the directories and repositories on my local machine.

# Needs
# Phase 1: (Manual)
#   - Ensure no files or directories need to be removed or deleted.
#   - Ensure all of the files and directories have the proper names/titles
#
# Phase 2: (Script)
#   - Ensure all the proper directories and sub-directories are made.
#  - Write script to create the tree structure desired
#  - Use the second half of the script to move everything into the appropriate places



# IMPORTANT:
# Ensure that no .git files are present and git is not initalized in the local parent directories because it will mess uo the path in GH.
# If you are going to move/rename folders or files you must do it locally and ensure no major chains were broken prior to pushing up to github

#!/bin/bash

ROOT="$HOME/Desktop/Coding/git"

# Define the folder moves (source → target directory)
MOVE_LIST=(
  "howmuchdoineed apps"
  "WhatWeEating apps"
  "techtunes apps"
  "personal_site apps"

  "desktop_cleanup_MacOS scripts"
  "desktop_cleanup_windows scripts"
  "huntress_install scripts"
  "IntuneAutopilot scripts"
  "sys_info scripts"

  "programming_fundamentals programming"
  "python programming"

  "terraform terraform"

  "vault_encryptor utilities"
  "text_to_markdown utilities"

  "resources resources"
  "backups backups"
)

echo "🔧 Starting reorganization..."

for entry in "${MOVE_LIST[@]}"; do
  folder=$(echo $entry | cut -d' ' -f1)
  target=$(echo $entry | cut -d' ' -f2)

  src="$ROOT/$folder"
  dest="$ROOT/$target"

  if [ -d "$src" ]; then
    mkdir -p "$dest"
    echo "📂 Moving $folder → $target/"
    mv "$src" "$dest/"
  else
    echo "⚠️  Skipping $folder — not found"
  fi
done

echo "✅ All done. Folder structure is now organized!"