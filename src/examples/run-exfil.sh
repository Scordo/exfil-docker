# Create directories which will contain generated data
mkdir -p "$(pwd)/data/MatchSettings"
mkdir -p "$(pwd)/data/Saved"
mkdir -p "$(pwd)/data/ServerSettings"

# change permissions, so that the container can write to them
sudo chmod -R 777 "$(pwd)/data"

docker run \
    -d \
    -e EXFIL_SERVER_NAME="Your Server Name" \
    -e EXFIL_MAX_PLAYERS=16 \
    -e EXFIL_SERVER_ROLES="YourSteamID|YourSteamName|Admin" \
    -v $(pwd)/data/MatchSettings:/home/steam/exfil-dedicated/Exfil/MatchSettings/ \
    -v $(pwd)/data/Saved:/home/steam/exfil-dedicated/Exfil/Saved/ \
    -v $(pwd)/data/ServerSettings:/home/steam/exfil-dedicated/Exfil/ServerSettings/ \
    --pull always \
    --name=exfilserver \
    ghcr.io/scordo/exfil-docker/server:latest
