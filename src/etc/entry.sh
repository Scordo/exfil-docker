#region Helper functions

function set_json_config_value {
  local key=$1
  local value=$2
  local config=$3

  local jq_args=('--arg' 'value' "${value}" "${key} = \$value" "${config}" )
  echo $(jq "${jq_args[@]}") > $config
}

function get_random_server_name {
  array=()
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

  echo "Loading Exfil Server from Steam"
  bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
                  +login ${STEAM_USER} ${STEAM_PASSWORD} ${STEAM_TOKEN} \
                  +app_update "${STEAMAPPID}" \
                  +quit
}

function configure_server_settings {
  # Server Configuration

  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  SERVER_SETTINGS_DIR="${STEAMAPPDIR}/Exfil/Saved/ServerSettings"
  SERVER_SETTINGS_FILE="${SERVER_SETTINGS_DIR}/ServerSettings.JSON"
  DEDICATED_SETTINGS_FILE="${SERVER_SETTINGS_DIR}/DedicatedSettings.JSON"
  server_settings_content="$(get_file_content "${SERVER_SETTINGS_FILE}")"
  dedicated_settings_content="$(get_file_content "${DEDICATED_SETTINGS_FILE}")"

  if [[ -z "${server_settings_content// }" ]]; then
    echo "Server settings are empty or do not exist. Creating default settings."
    mkdir -p "${SERVER_SETTINGS_DIR}"
    echo "{}" > "${SERVER_SETTINGS_FILE}"
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

  if [ -n "${EXFIL_SERVER_ADMINS}" ]; then
    echo "Found server admins: ${EXFIL_SERVER_ADMINS}"
      IFS=';' read -ra server_admins <<< "${EXFIL_SERVER_ADMINS}"

      for server_admin in "${server_admins[@]}"
      do
          admin_steam_id="${server_admin%=*}"
          admin_name="${server_admin#*=}"
          printf "\t> Adding '${admin_name}' with steam id '${admin_steam_id}'\n"
          set_json_config_value ".admin.\"${admin_steam_id}\"" "${admin_name}" "${SERVER_SETTINGS_FILE}"
      done
  fi
}

function start_server {
  # Pre Server Start Hook
  source "${STEAMAPPDIR}/pre-serverstart.sh"

  EF_SERVER_NAME=$(jq -r .ServerName "${DEDICATED_SETTINGS_FILE}")
  echo "Starting Exfil Server: ${EF_SERVER_NAME}"

  bash "${STEAMAPPDIR}/ExfilServer.sh"
}

#endregion

install_hooks
install_or_update_exfil
configure_server_settings
start_server
