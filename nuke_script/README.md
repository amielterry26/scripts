# 🔥 Nuke Script – macOS App Uninstaller

This is a precision-built shell script designed to **permanently remove unwanted applications** from macOS, including background processes, support files, launch agents, and caches. Inspired by clean terminal workflows, it includes smart detection, dry-run previews, and layered confirmation to prevent mistakes.

---

## 📦 Files Included

### `nuke_script.sh`
- The **core script** responsible for nuking apps.
- Designed to be run directly from the `/Applications` directory.
- Includes:
    - Smart fuzzy matching for `.app` files
    - Background process kill via keyword
    - Full removal of associated system and user files
    - Dry-run mode for safe previews
    - Confirmation prompts for safety

### `nuke_fetch.sh`
- A **helper script** that lives in your personal directory (e.g., `~/Desktop/Quick Script`)
- Copies `nuke_script.sh` into `/Applications`, navigates there, runs it, and offers to delete afterward.
- Lets you keep your scripts organized while ensuring they execute in the proper context.

> 💡 **Utilize the `nuke_fetch.sh` script to run from your personalized local directory** without cluttering your `/Applications` or Desktop.

---

## 🚀 How to Use

### 1. Run the Fetch Script

```bash
cd ~/Desktop/Quick\ Script
./nuke_fetch.sh
```

This will:
- Copy the actual nuke script from your GitHub folder
- Move it into `/Applications`
- Run it from there
- Prompt to remove the nuke script after execution

---

### 2. Follow the Prompts

You'll be guided through:

- 🔎 **App Name Guess**: Enter a fuzzy match (e.g., `zoom`, `adobe`)
- 📂 **Select from Options**: Choose the correct `.app` from a short list
- 🧠 **Process Keyword**: Enter or get help finding background processes (e.g., `zoom`, `spotify`)
- 🧪 **Dry Run Option**: Preview everything before actual deletion
- ☠️ **Confirmation**: Type `permanently nuke` to proceed
- ✅ **Finish**: The script performs all clean-up actions and shows the final results

---

## 🧠 FAQ

### ❓ What’s the “process keyword”?

This refers to the name of the background processes the app runs under, used to kill and clean up services.

Examples:
| App                  | Process Keyword |
|----------------------|------------------|
| Creative Cloud       | `adobe`          |
| Zoom.us              | `zoom`           |
| Spotify              | `spotify`        |
| Dropbox              | `dropbox`        |

If you're unsure, the script allows you to:
- Use `?` to auto-search running processes
- Use a fallback default suggestion

---

## 🧪 Dry Run Mode

Choose the dry run option to **see what would be deleted** without actually performing any actions.

This is useful for:
- Safety testing
- Verifying correct process keywords
- Previewing full paths and kill actions

---

## 📁 File Structure (Suggested)

```
~/Desktop/Quick Script/
├── nuke_fetch.sh
~/Coding/git/scripts/nuke_script/
├── nuke_script.sh
```

---

## Author

Crafted with obsessive attention to detail by 🧙🏾‍♂️‍ [Amiel Terry](https://amielterry.me) & Arcane Systems LLC