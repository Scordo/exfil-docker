
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

# Pre Server Start Hook
source "${STEAMAPPDIR}/pre-serverstart.sh"

echo "Starting Exfil Server: ${EXFIL_SERVER_NAME}"

# TODO: Add parameters via commandline
bash "${STEAMAPPDIR}/ExfilServer.sh" #\
			#EXFIL_SERVER_NAME="${EXFIL_SERVER_NAME}" \
			#EXFIL_MAX_PLAYERS="${EXFIL_MAX_PLAYERS}"