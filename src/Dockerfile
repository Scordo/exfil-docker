############################################################
# Dockerfile that builds a Exfil Gameserver
# Reference: https://hub.docker.com/r/cm2network/steamcmd
############################################################
FROM cm2network/steamcmd:root


LABEL maintainer="admin@dev-com.de"

ENV STEAMAPPID 3093190
ENV STEAMAPP exfil
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"

COPY etc/entry.sh ${HOMEDIR}
COPY etc/pre-serverstart.sh "/etc/pre-serverstart.sh"
COPY etc/pre-serverupdate.sh "/etc/pre-serverupdate.sh"

# The directories below are created to allow mounting them (will be created with steamcmd in entry.sh later)
RUN set -x \
	&& mkdir -p "${STEAMAPPDIR}" \
    && mkdir -p "${STEAMAPPDIR}/Exfil/MatchSettings" \
    && mkdir -p "${STEAMAPPDIR}/Exfil/Saved" \
    && mkdir -p "${STEAMAPPDIR}/Exfil/ServerSettings" \
	&& chmod -R 755 "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}" \
	&& chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}"

ENV EXFIL_SERVER_NAME="Exfil Server" \
	EXFIL_MAX_PLAYERS=32

# Switch to user
USER ${USER}

WORKDIR ${HOMEDIR}

CMD ["bash", "entry.sh"]