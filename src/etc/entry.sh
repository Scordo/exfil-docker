
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

# Install hooks if they don't already exist
if [[ ! -f "${STEAMAPPDIR}/pre-serverupdate.sh" ]] ; then
    cp /etc/pre-serverupdate.sh "${STEAMAPPDIR}/pre-serverupdate.sh"
fi
if [[ ! -f "${STEAMAPPDIR}/pre-serverstart.sh" ]] ; then
    cp /etc/pre-serverstart.sh "${STEAMAPPDIR}/pre-serverstart.sh"
fi

# Pre Server Update Hook
source "${STEAMAPPDIR}/pre-serverupdate.sh"

echo "Loading Exfil Server from Steam"
bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
                +login ${STEAM_USER} ${STEAM_PASSWORD} ${STEAM_TOKEN} \
                +app_update "${STEAMAPPID}" \
                +quit

# Server Configuration

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SERVER_SETTINGS_DIR="${STEAMAPPDIR}/Exfil/Saved/ServerSettings"
SERVER_SETTINGS_FILE="${SERVER_SETTINGS_DIR}/ServerSettings.JSON"

if [[ -f $SERVER_SETTINGS_FILE ]]; then
    settings_content=$(<"$SERVER_SETTINGS_FILE")
else
    settings_content=""
fi

if [[ -z "${settings_content// }" ]]; then
    echo "Server settings are empty or do not exist. Creating default settings."
    mkdir -p "${SERVER_SETTINGS_DIR}"
    echo "{}" > "${SERVER_SETTINGS_FILE}"
    set_json_config_value '.ServerName' "$(get_random_server_name)" "${SERVER_SETTINGS_FILE}"
    set_json_config_value '.MaxPlayerCount' "32" "${SERVER_SETTINGS_FILE}"
fi

if [ -n "${EXFIL_SERVER_NAME}" ]; then
	echo "Server name will be set to: ${EXFIL_SERVER_NAME}"
    set_json_config_value '.ServerName' "${EXFIL_SERVER_NAME}" "${SERVER_SETTINGS_FILE}"
fi

if [ -n "${EXFIL_MAX_PLAYERS}" ]; then
    echo "Max player will be set to: ${EXFIL_MAX_PLAYERS}"
	set_json_config_value '.MaxPlayerCount' "${EXFIL_MAX_PLAYERS}" "${SERVER_SETTINGS_FILE}"
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

# Pre Server Start Hook
source "${STEAMAPPDIR}/pre-serverstart.sh"

EF_SERVER_NAME=$(jq -r .ServerName "${SERVER_SETTINGS_FILE}")
echo "Starting Exfil Server: ${EF_SERVER_NAME}"

bash "${STEAMAPPDIR}/ExfilServer.sh"