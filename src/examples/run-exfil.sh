# Create directories which will contain generated data
mkdir -p "$(pwd)/data/MatchSettings"
mkdir -p "$(pwd)/data/Saved"
mkdir -p "$(pwd)/data/ServerSettings"

# change permissions, so that the container can write to them
sudo chmod -R 777 "$(pwd)/data"

docker run \
    -d \
    -e STEAM_USER=YourSteamServerAccountName \
    -e STEAM_PASSWORD=YourSteamServerAccountPassword \
    -e STEAM_TOKEN= \
    -v $(pwd)/data/MatchSettings:/home/steam/exfil-dedicated/Exfil/MatchSettings/ \
    -v $(pwd)/data/Saved:/home/steam/exfil-dedicated/Exfil/Saved/ \
    -v $(pwd)/data/ServerSettings:/home/steam/exfil-dedicated/Exfil/ServerSettings/ \
    --name=exfilserver \
    exfil-server