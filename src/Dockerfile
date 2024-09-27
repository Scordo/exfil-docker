############################################################
# Dockerfile that builds a Exfil Gameserver
# Reference: https://hub.docker.com/r/cm2network/steamcmd
############################################################
FROM cm2network/steamcmd:root


LABEL maintainer="admin@dev-com.de"
LABEL org.opencontainers.image.source=https://github.com/Scordo/exfil-docker

ENV STEAMAPPID=3093190
ENV STEAMAPP=exfil
ENV STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"
ENV EXFIL_SERVER_PORT=7777
ENV EXFIL_SERVER_QUERY_PORT=27015

COPY etc/entry.sh ${HOMEDIR}
COPY etc/pre-serverstart.sh "/etc/pre-serverstart.sh"
COPY etc/pre-serverupdate.sh "/etc/pre-serverupdate.sh"

# The directories below are created to allow mounting them (will be created with steamcmd in entry.sh later)
RUN set -x \
	&& apt-get update -qq > /dev/null \
	&& apt-get install -qq jq > /dev/null  \
	&& mkdir -p "${STEAMAPPDIR}" \
    && mkdir -p "${STEAMAPPDIR}/Exfil/Saved/Logs" \
	&& mkdir -p "${STEAMAPPDIR}/Exfil/Saved/Config" \
	&& mkdir -p "${STEAMAPPDIR}/Exfil/Saved/MatchData" \
	&& mkdir -p "${STEAMAPPDIR}/Exfil/Saved/MatchSettings" \
    && mkdir -p "${STEAMAPPDIR}/Exfil/Saved/ServerSettings" \
	&& chmod -R 755 "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}" \
	&& chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}"

# Switch to user
USER ${USER}

WORKDIR ${HOMEDIR}

CMD ["bash", "entry.sh"]