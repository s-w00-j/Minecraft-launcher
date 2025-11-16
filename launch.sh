#!/usr/bin/env bash
# mc-launcher.sh - Simple shell-based Minecraft launcher (Linux / macOS)
# Usage: ./mc-launcher.sh
# Requirements: bash, awk, sed, jq (optional for JSON edit), java (for jar launch)
# NOTE: This script does NOT bypass authentication. Use your official launcher or provide a jar that handles login.

BASE_DIR="${HOME}/.mc-launcher"
PROFILES_DIR="${BASE_DIR}/profiles"
mkdir -p "${PROFILES_DIR}"

# Helper: print a header
header() {
  echo
  echo "======================================"
  echo "        Simple Minecraft Launcher     "
  echo "======================================"
}

# List profiles
list_profiles() {
  echo
  echo "Saved profiles:"
  i=0
  for f in "${PROFILES_DIR}"/*.cfg 2>/dev/null; do
    [ -e "$f" ] || { echo "  (none yet)"; return; }
    ((i++))
    name=$(basename "$f" .cfg)
    desc=$(grep '^DESCRIPTION=' "$f" 2>/dev/null | cut -d'=' -f2-)
    printf "  %2d) %s — %s\n" "$i" "$name" "${desc:-(no description)}"
  done
}

# Create profile
create_profile() {
  read -rp "Profile name (no spaces): " pname
  [ -z "$pname" ] && { echo "Cancelled."; return; }
  target="${PROFILES_DIR}/${pname}.cfg"
  if [ -e "$target" ]; then
    echo "Profile exists. Overwrite? (y/N)"
    read -rn1 over
    echo
    [ "$over" != "y" ] && { echo "Cancelled."; return; }
  fi
  echo "Path to jar or launcher executable (absolute or relative):"
  read -rp "> " jarpath
  echo "JVM memory (example: 2G or 4096M). Leave empty for default."
  read -rp "> " mem
  echo "Extra JVM args (eg: -Dfml.ignoreInvalidMinecraftCertificates=true). Leave empty if none."
  read -rp "> " jvmargs
  echo "Command-line args to the jar (if any). Leave empty if none."
  read -rp "> " jarargs
  echo "Short description:"
  read -rp "> " desc
  cat > "$target" <<EOF
JAR=${jarpath}
MEM=${mem}
JVMARGS=${jvmargs}
JARARGS=${jarargs}
DESCRIPTION=${desc}
EOF
  echo "Saved profile '${pname}'."
}


edit_profile() {
  list_profiles
  echo
  read -rp "Profile name to edit: " pname
  [ -z "$pname" ] && { echo "Cancelled."; return; }
  target="${PROFILES_DIR}/${pname}.cfg"
  if command -v ${EDITOR:-nano} >/dev/null 2>&1; then
    ${EDITOR:-nano} "$target"
  else
    echo "No editor found. Opening with cat (readonly):"
    cat "$target"
  fi
}

# Launch profile
launch_profile() {
  list_profiles
  echo
  read -rp "Profile name to launch: " pname
  [ -z "$pname" ] && { echo "Cancelled."; return; }
  cfg="${PROFILES_DIR}/${pname}.cfg"
  if [ ! -f "$cfg" ]; then
    echo "Profile not found: $cfg"; return
  fi
  # load config
  . "$cfg"
  if [ -z "$JAR" ]; then
    echo "Profile corrupt: JAR path empty."; return
  fi

  if [ -x "$JAR" ]; then
    echo "Running executable: $JAR $JARARGS"
    nohup "$JAR" $JARARGS >/dev/null 2>&1 &
    echo "Launched in background (nohup)."
    return
  fi

  # If file ends with .jar, launch with java
  if [[ "$JAR" == *.jar ]]; then
    if ! command -v java >/dev/null 2>&1; then
      echo "Java not found. Install Java (OpenJDK) and retry."
      return
    fi
    memarg=""
    if [ -n "$MEM" ]; then memarg="-Xmx${MEM} -Xms${MEM%?}"; fi
    # Build command
    cmd=(java)
    [ -n "$memarg" ] && cmd+=("$memarg")
    # Split JVMARGS by spaces (simple)
    if [ -n "$JVMARGS" ]; then
      # naive split
      for a in $JVMARGS; do cmd+=("$a"); done
    fi
    cmd+=("-jar" "$JAR")
    if [ -n "$JARARGS" ]; then
      for a in $JARARGS; do cmd+=("$a"); done
    fi

    echo "Launching: ${cmd[*]}"
 
    if command -v setsid >/dev/null 2>&1; then
      setsid "${cmd[@]}" >/dev/null 2>&1 &
    else
      nohup "${cmd[@]}" >/dev/null 2>&1 &
    fi
    echo "Launched in background."
    return
  fi


  if [ -d "$JAR" ]; then
    # look for AppImage or linux executable
    for execname in MultiMC AppImage minecraft-launcher launcher; do
      if [ -x "${JAR}/${execname}" ]; then
        echo "Found executable ${JAR}/${execname}, launching..."
        nohup "${JAR}/${execname}" $JARARGS >/dev/null 2>&1 &
        echo "Launched in background."
        return
      fi
    done
    echo "Directory provided but no executable found inside. Please point to the launcher executable or a jar."
    return
  fi

  echo "Unknown JAR/executable type or file not found: $JAR"
}

# Remove profile
remove_profile() {
  list_profiles
  echo
  read -rp "Profile name to delete: " pname
  [ -z "$pname" ] && { echo "Cancelled."; return; }
  target="${PROFILES_DIR}/${pname}.cfg"
  [ -f "$target" ] || { echo "Profile not found."; return; }
  read -rp "Really delete ${pname}? (y/N): " yn
  [ "$yn" = "y" ] && rm -f "$target" && echo "Deleted."
}


create_example() {
  cat > "${PROFILES_DIR}/example.cfg" <<EOF
JAR=/path/to/your/forge-or-multimc-or-official-launcher.jar
MEM=4G
JVMARGS=-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions
JARARGS=
DESCRIPTION=Example profile — edit path to your jar/executable.
EOF
  echo "Example profile created at ${PROFILES_DIR}/example.cfg"
}

while true; do
  header
  echo "Choose an action:"
  echo "  1) List profiles"
  echo "  2) Create profile"
  echo "  3) Edit profile"
  echo "  4) Launch profile"
  echo "  5) Delete profile"
  echo "  6) Create example profile"
  echo "  0) Exit"
  read -rp "> " opt
  case "$opt" in
    1) list_profiles; read -rp $'\nPress Enter to continue...';;
    2) create_profile; read -rp $'\nPress Enter to continue...';;
    3) edit_profile; read -rp $'\nPress Enter to continue...';;
    4) launch_profile; read -rp $'\nPress Enter to continue...';;
    5) remove_profile; read -rp $'\nPress Enter to continue...';;
    6) create_example; read -rp $'\nPress Enter to continue...';;
    0) echo "Bye!"; exit 0;;
    *) echo "Invalid option.";;
  esac
done
