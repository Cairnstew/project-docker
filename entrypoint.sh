#!/bin/bash
set -e


INI_FILE="/home/pzuser/Zomboid/Server/servertest.ini"

# Fix permissions if running as pzuser
if [ "$(id -u)" -ne 0 ]; then
  echo "Fixing permissions for Zomboid directory..."
  sudo chown -R "$(id -u):$(id -g)" "$ZOMBOID"
fi

# Helper to set or update a key=value pair in the ini file
set_ini_value() {
  local key="$1"
  local value="$2"

  # Escape special chars in key for sed (if needed)
  local sed_key
  sed_key=$(printf '%s\n' "$key" | sed -e 's/[]\/$*.^[]/\\&/g')

  # Check if key exists in ini
  if grep -qE "^$sed_key=" "$INI_FILE"; then
    # Replace line
    sed -i "s/^$sed_key=.*/$key=$value/" "$INI_FILE"
  else
    # Append line
    echo "$key=$value" >> "$INI_FILE"
  fi
}

# Helper to get environment variable or default if unset/empty
get_env_or_default() {
  local var="$1"
  local default="$2"
  local val="${!var}"
  if [ -z "$val" ]; then
    echo "$default"
  else
    echo "$val"
  fi
}

# Declare keys and defaults as associative array (bash 4+)
declare -A defaults=(
  [PVP]=true
  [PauseEmpty]=true
  [GlobalChat]=true
  [ChatStreams]="s,r,a,w,y,sh,f,all"
  [Open]=true
  [ServerWelcomeMessage]="Welcome to Project Zomboid Multiplayer!"
  [LogLocalChat]=false
  [AutoCreateUserInWhiteList]=false
  [DisplayUserName]=true
  [ShowFirstAndLastName]=false
  [SpawnPoint]="0,0,0"
  [SafetySystem]=true
  [ShowSafety]=true
  [SafetyToggleTimer]=2
  [SafetyCooldownTimer]=3
  [SpawnItems]=""
  [DefaultPort]=16261
  [ResetID]=572058526
  [Mods]=""
  [Map]="Muldraugh, KY"
  [DoLuaChecksum]=true
  [DenyLoginOnOverloadedServer]=true
  [Public]=true
  [PublicName]=""
  [PublicDescription]=""
  [MaxPlayers]=16
  [PingFrequency]=10
  [PingLimit]=250
  [HoursForLootRespawn]=0
  [MaxItemsForLootRespawn]=4
  [ConstructionPreventsLootRespawn]=true
  [DropOffWhiteListAfterDeath]=false
  [NoFire]=false
  [AnnounceDeath]=true
  [MinutesPerPage]=1.0
  [SaveWorldEveryMinutes]=0
  [PlayerSafehouse]=true
  [AdminSafehouse]=false
  [SafehouseAllowTrepass]=true
  [SafehouseAllowFire]=true
  [SafehouseAllowLoot]=true
  [SafehouseAllowRespawn]=false
  [SafehouseDaySurvivedToClaim]=0
  [SafeHouseRemovalTime]=144
  [AllowDestructionBySledgehammer]=true
  [KickFastPlayers]=false
  [ServerPlayerID]=1920185881
  [RCONPort]=27015
  [RCONPassword]=""
  [DiscordEnable]=false
  [DiscordToken]=""
  [DiscordChannel]=""
  [DiscordChannelID]=""
  [Password]=""
  [MaxAccountsPerUser]=0
  [SleepAllowed]=false
  [SleepNeeded]=false
  [SteamPort1]=8766
  [SteamPort2]=8767
  [WorkshopItems]=""
  [SteamScoreboard]=true
  [SteamVAC]=true
  [UPnP]=true
  [UPnPLeaseTime]=86400
  [UPnPZeroLeaseTimeFallback]=true
  [UPnPForce]=true
  [CoopServerLaunchTimeout]=20
  [CoopMasterPingTimeout]=60
  [VoiceEnable]=true
  [VoiceComplexity]=5
  [VoicePeriod]=20
  [VoiceSampleRate]=24000
  [VoiceBuffering]=8000
  [VoiceMinDistance]=10.0
  [VoiceMaxDistance]=300.0
  [Voice3D]=true
  [PhysicsDelay]=500
  [SpeedLimit]=70.0
  [server_browser_announced_ip]=""
  [UseTCPForMapDownloads]=false
  [PlayerRespawnWithSelf]=false
  [PlayerRespawnWithOther]=false
  [FastForwardMultiplier]=40.0
  [PlayerSaveOnDamage]=true
  [SaveTransactionID]=false
  [DisableSafehouseWhenPlayerConnected]=false
  [Faction]=true
  [FactionDaySurvivedToCreate]=0
  [FactionPlayersRequiredForTag]=1
  [AllowTradeUI]=true
  [DisableRadioStaff]=false
  [DisableRadioAdmin]=true
  [DisableRadioGM]=true
  [DisableRadioOverseer]=false
  [DisableRadioModerator]=false
  [DisableRadioInvisible]=true
  [ClientCommandFilter]="-vehicle.*;+vehicle.damageWindow;+vehicle.fixPart;+vehicle.installPart;+vehicle.uninstallPart"
  [ItemNumbersLimitPerContainer]=0
  [BloodSplatLifespanDays]=0
  [AllowNonAsciiUsername]=false
  [BanKickGlobalSound]=true
  [RemovePlayerCorpsesOnCorpseRemoval]=false
  [ZombieUpdateMaxHighPriority]=50
  [ZombieUpdateDelta]=0.5
  [ZombieUpdateRadiusLowPriority]=45.0
  [ZombieUpdateRadiusHighPriority]=10.0
  [TrashDeleteAll]=false
  [PVPMeleeWhileHitReaction]=false
  [MouseOverToSeeDisplayName]=true
  [HidePlayersBehindYou]=true
  [PVPMeleeDamageModifier]=30.0
  [PVPFirearmDamageModifier]=50.0
  [CarEngineAttractionModifier]=0.5
  [PlayerBumpPlayer]=false
  [HoursForWorldItemRemoval]=0.0
  [WorldItemRemovalList]="Base.Vest,Base.Shirt,Base.Blouse,Base.Skirt,Base.Shoes"
)

# Check ini file exists
if [ ! -f "$INI_FILE" ]; then
  echo "Warning: $INI_FILE not found, creating a new one."
  mkdir -p "$(dirname "$INI_FILE")"  # Ensure parent directories exist
  touch "$INI_FILE"
fi

# Iterate and update ini file
for key in "${!defaults[@]}"; do
  value=$(get_env_or_default "$key" "${defaults[$key]}")
  set_ini_value "$key" "$value"
done

echo "Updated $INI_FILE with environment or default values."



if [ "$UPDATE_SERVER" = "1" ]; then
  echo "Updating Project Zomboid server..."
  steamcmd.sh +runscript /home/pzuser/update_zomboid.txt
else
  echo "Skipping server update."
fi


ARGS=""

# Set the server memory. Units are accepted (1024m=1Gig, 2048m=2Gig, 4096m=4Gig): Example: 1024m
if [ -n "${MEMORY}" ]; then
  ARGS="${ARGS} -Xmx${MEMORY} -Xms${MEMORY}"
fi

# Option to perform a Soft Reset
if [ "${SOFTRESET}" == "1" ] || [ "${SOFTRESET,,}" == "true" ]; then
  ARGS="${ARGS} -Dsoftreset"
fi

# End of Java arguments
ARGS="${ARGS} -- "

# Runs a coop server instead of a dedicated server. Disables the default admin from being accessible.
# - Default: Disabled
if [ "${COOP}" == "1" ] || [ "${COOP,,}" == "true" ]; then
  ARGS="${ARGS} -coop"
fi

# Disables Steam integration on server.
# - Default: Enabled
if [ "${NOSTEAM}" == "1" ] || [ "${NOSTEAM,,}" == "true" ]; then
  ARGS="${ARGS} -nosteam"
fi

# Sets the path for the game data cache dir.
# - Default: ~/Zomboid
# - Example: /server/Zomboid/data
if [ -n "${CACHEDIR}" ]; then
  ARGS="${ARGS} -cachedir=${CACHEDIR}"
fi

# Option to control where mods are loaded from and the order. Any of the 3 keywords may be left out and may appear in any order.
# - Default: workshop,steam,mods
# - Example: mods,steam
if [ -n "${MODFOLDERS}" ]; then
  ARGS="${ARGS} -modfolders ${MODFOLDERS}"
fi

# Launches the game in debug mode.
# - Default: Disabled
if [ "${DEBUG}" == "1" ] || [ "${DEBUG,,}" == "true" ]; then
  ARGS="${ARGS} -debug"
fi

# Option to set the admin username. Current admins will not be changed.
if [ -n "${ADMINUSERNAME}" ]; then
  ARGS="${ARGS} -adminusername ${ADMINUSERNAME}"
fi

# Option to bypasses the enter-a-password prompt when creating a server.
# This option is mandatory the first startup or will be asked in console and startup will fail.
# Once is launched and data is created, then can be removed without problem.
# Is recommended to remove it, because the server logs the arguments in clear text, so Admin password will be sent to log in every startup.
if [ -n "${ADMINPASSWORD}" ]; then
  ARGS="${ARGS} -adminpassword ${ADMINPASSWORD}"
fi

# You can choose a different servername by using this option when starting the server.
if [ -n "${SERVERNAME}" ]; then
  ARGS="${ARGS} -servername \"${SERVERNAME}\""
else
  # If not servername is set, use the default name in the next step
  SERVERNAME="servertest"
fi

# Option to enable/disable VAC on Steam servers. On the server command-line use -steamvac true/false. In the server's INI file, use STEAMVAC=true/false.
if [ -n "${STEAMVAC}" ]; then
  ARGS="${ARGS} -steamvac ${STEAMVAC,,}"
fi

exec /opt/pzserver/start-server.sh $ARGS
#exec bash
