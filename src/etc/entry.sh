#region Helper functions

function set_json_config_value {
  local key=$1
  local value=$2
  local config=$3

  local jq_args=('--arg' 'value' "${value}" "${key} = \$value" "${config}" )
  echo $(jq "${jq_args[@]}") > $config
}

function fn_add_role_to_json_config {
  local steamid=$1
  local name=$2
  local role=$3
  local config=$4

  local jq_args=('--arg' 'steamid' "${steamid}" '--arg' 'name' "${name}" '--arg' 'role' "${role}" ".AdminList += [{ steamId: \$steamid, name: \$name, adminLevel: \$role }] " "${config}"  )
  echo $(jq "${jq_args[@]}") > $config
}

function fn_remove_role_from_json_config {
  local steamid=$1
  local config=$2

  local jq_args=('--arg' 'steamid' "${steamid}" "del(.AdminList[] | select(.steamId==\$steamid))" "${config}"  )
  echo $(jq "${jq_args[@]}") > $config
}

function get_random_server_name {
  local array=()
  for i in {a..z} {A..Z} {0..9};
  do
      array[$RANDOM]=$i
  done

  echo "Server $(printf %s ${array[@]::8} $'\n')"
}

function get_file_content {
  if [[ -f $1 ]]; then
    local content=$(<"$1")
  else
    local content=""
  fi

  echo "${content}"
}

#endregion

#region main functions

function install_hooks {
  # Install hooks if they don't already exist
  if [[ ! -f "${STEAMAPPDIR}/pre-serverupdate.sh" ]] ; then
    cp /etc/pre-serverupdate.sh "${STEAMAPPDIR}/pre-serverupdate.sh"
  fi
  if [[ ! -f "${STEAMAPPDIR}/pre-serverstart.sh" ]] ; then
    cp /etc/pre-serverstart.sh "${STEAMAPPDIR}/pre-serverstart.sh"
  fi
}

function install_or_update_exfil {
  # Pre Server Update Hook
  source "${STEAMAPPDIR}/pre-serverupdate.sh"

  if [ -n "${STEAM_BETA_BRANCH}" ]
  then
    echo "Loading Exfil Server from Steam (branch: ${STEAM_BETA_BRANCH})"

    bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
                    +login anonymous \
                    +app_update "${STEAMAPPID}" \
                    -beta "${STEAM_BETA_BRANCH}" \
                    -betapassword "${STEAM_BETA_PASSWORD}" \
                    +quit
  else
    echo "Loading Exfil Server from Steam"

    bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
                    +login anonymous \
                    +app_update "${STEAMAPPID}" \
                    +quit
  fi
}

function configure_server_settings {
  # Server Configuration

  local SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  local SERVER_SETTINGS_DIR="${STEAMAPPDIR}/Exfil/Saved/ServerSettings"
  local SERVER_SETTINGS_FILE="${SERVER_SETTINGS_DIR}/ServerSettings.JSON"
  local ADMIN_SETTINGS_FILE="${SERVER_SETTINGS_DIR}/AdminSettings.JSON"
  DEDICATED_SETTINGS_FILE="${SERVER_SETTINGS_DIR}/DedicatedSettings.JSON"
  local server_settings_content="$(get_file_content "${SERVER_SETTINGS_FILE}")"
  local dedicated_settings_content="$(get_file_content "${DEDICATED_SETTINGS_FILE}")"
  local admin_settings_content="$(get_file_content "${ADMIN_SETTINGS_FILE}")"

  if [[ -z "${server_settings_content// }" ]]; then
    echo "Server settings are empty or do not exist. Creating default settings."
    mkdir -p "${SERVER_SETTINGS_DIR}"
    echo '{"AutoStartTimer":0,"MinAutoStartPlayers": "2","AddAutoStartTimeOnPlayerJoin":20}' > "${SERVER_SETTINGS_FILE}"
  fi

  if [[ -z "${dedicated_settings_content// }" ]]; then
    echo "Dedicated server settings are empty or do not exist. Creating default settings."
    mkdir -p "${SERVER_SETTINGS_DIR}"
    echo "{}" > "${DEDICATED_SETTINGS_FILE}"
    set_json_config_value '.ServerName' "$(get_random_server_name)" "${DEDICATED_SETTINGS_FILE}"
    set_json_config_value '.MaxPlayerCount' "32" "${DEDICATED_SETTINGS_FILE}"
  fi

  if [ -n "${EXFIL_SERVER_NAME}" ]; then
    echo "Server name will be set to: ${EXFIL_SERVER_NAME}"
    set_json_config_value '.ServerName' "${EXFIL_SERVER_NAME}" "${DEDICATED_SETTINGS_FILE}"
  fi

  if [ -n "${EXFIL_MAX_PLAYERS}" ]; then
    echo "Max player will be set to: ${EXFIL_MAX_PLAYERS}"
    set_json_config_value '.MaxPlayerCount' "${EXFIL_MAX_PLAYERS}" "${DEDICATED_SETTINGS_FILE}"
  fi

  if [ -n "${EXFIL_SERVER_PASSWORD}" ]; then
    echo "Server password will be set to: ${EXFIL_SERVER_PASSWORD}"
    set_json_config_value '.ServerPassword' "${EXFIL_SERVER_PASSWORD}" "${DEDICATED_SETTINGS_FILE}"
  fi

  if [ -n "${EXFIL_SERVER_ROLES}" ]; then
    if [[ -z "${admin_settings_content// }" ]]; then
        echo "Admin settings are empty or do not exist. Creating default settings."
        mkdir -p "${SERVER_SETTINGS_DIR}"
        echo '{"AdminList":[],"BanList":[]}' > "${ADMIN_SETTINGS_FILE}"
    fi

    echo "Found server roles: ${EXFIL_SERVER_ROLES}"
    IFS=';' read -ra server_roles <<< "${EXFIL_SERVER_ROLES}"

    for server_role in "${server_roles[@]}"
    do
        IFS='|' read -ra role_parts <<< "${server_role}"

        if [[ ${#role_parts[@]} -ne 3 ]]; then
            echo "Invalid value for server roles. There have to be exactly 3 parts in '${server_role}' separated by '|'. SteamId|Name|Role"
            exit 1
        fi

        entry_steam_id="${role_parts[0]}"
        entry_name="${role_parts[1]}"
        entry_role="${role_parts[2]}"

        printf "\t> Adding '${entry_name}' with steam id '${entry_steam_id}' as '${entry_role}'\n"

        fn_remove_role_from_json_config "$entry_steam_id" $ADMIN_SETTINGS_FILE
        fn_add_role_to_json_config "$entry_steam_id" "${entry_name}" "${entry_role}" $ADMIN_SETTINGS_FILE
    done
  fi
}

function start_server {
  local server_port="7777"
  local server_query_port="27015"

  # Pre Server Start Hook
  source "${STEAMAPPDIR}/pre-serverstart.sh"

  local EF_SERVER_NAME=$(jq -r .ServerName "${DEDICATED_SETTINGS_FILE}")
  echo "Starting Exfil Server: ${EF_SERVER_NAME}"

  if [ -n "${EXFIL_SERVER_PORT}" ]; then
    server_port="${EXFIL_SERVER_PORT}"
  fi

  if [ -n "${EXFIL_SERVER_QUERY_PORT}" ]; then
    server_query_port="${EXFIL_SERVER_QUERY_PORT}"
  fi

  bash "${STEAMAPPDIR}/ExfilServer.sh" "-port=${EXFIL_SERVER_PORT}" "-QueryPort=${EXFIL_SERVER_QUERY_PORT}"
}

#endregion

install_hooks
install_or_update_exfil
configure_server_settings
start_server
