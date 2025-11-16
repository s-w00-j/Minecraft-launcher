# Minecraft-launcher
# mc-launcher.sh - Simple shell-based Minecraft launcher (Linux / macOS)
***
## How to launch:
```
/mc-launcher.sh
```
***
### An installed launcher executable (e.g., ~/Downloads/multiMC/MultiMC or an AppImage), or

### A *.jar (e.g., a modded launcher jar or server jar you want to run), or

### A directory that contains an executable (the script will try MultiMC, AppImage, minecraft-launcher, launcher).

Launch it from the menu. The script starts the process in background (so the terminal is free).

## Notes, tips & limitations
This wrapper does not perform Mojang/Microsoft login or download Minecraft game assets for you. Use your official launcher (point a profile to its executable) or MultiMC / Prism Launcher / vanilla client that you already have set up.

If you want a fully-featured programmatic launcher (auto-download versions, handle authentication, manage libraries/assets), that is a much larger project that uses the official Minecraft version manifests and auth flows (and typically involves using an existing library such as minecraft-launcher-lib or projects like MultiMC). I can sketch that out or produce a more advanced script in the same reply if you want — but it will be longer and require handling OAuth tokens.

Works best on Linux/macOS. On Windows, use WSL or convert to a PowerShell script.
