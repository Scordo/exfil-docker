# What is EXFIL?

EXFIL is a tactical first person shooter which aims to provide gamers with sandbox game modes with all the controls they need to play them the way they like. We want to be sure we are providing value up front to gamers while also laying out a road map of how we intend to evolve the product.

> [EXFIL](https://store.steampowered.com/app/860020/EXFIL/)

<img src="https://www.misultin.com/img/exfil-military.jpg" alt="logo" width="700"/>

## How to use this image

### Hosting a simple game server

Running using Docker:

```console
$ docker run -d --name=exfilserver --pull always ghcr.io/scordo/exfil-docker/server:latest
```

Running using a bind mount for data persistence on container recreation:

```console
$ # Create directories which will contain generated data
$ mkdir -p "$(pwd)/data/MatchSettings"
$ mkdir -p "$(pwd)/data/Saved"
$ mkdir -p "$(pwd)/data/ServerSettings"

$ # change permissions, so that the container can write to them
$ sudo chmod -R 777 "$(pwd)/data"

$ docker run \
    -d \
    -e EXFIL_SERVER_NAME="Your Server Name" \
    -e EXFIL_MAX_PLAYERS=16 \
    -e EXFIL_SERVER_ROLES="YourSteamID|YourSteamName|Role" \
    -v $(pwd)/data/MatchSettings:/home/steam/exfil-dedicated/Exfil/MatchSettings/ \
    -v $(pwd)/data/Saved:/home/steam/exfil-dedicated/Exfil/Saved/ \
    -v $(pwd)/data/ServerSettings:/home/steam/exfil-dedicated/Exfil/ServerSettings/ \
    --pull always \
    --name=exfilserver \
    ghcr.io/scordo/exfil-docker/server:latest
```

or using docker-compose, see [examples](src/examples/docker-compose.yml):

```console
# Remember to update Steam account details in docker-compose.yml
$ docker compose --file src/examples/docker-compose.yml up -d
```

You must have at least **5GB** of free disk space! See [System Requirements](./#system-requirements).

**The container will automatically update the game on startup, so if there is a game update just restart the container.**

## Configuration

### System Requirements

Minimum system requirements are:

* 2 CPUs
* 4GiB RAM
* 5GB of free disk space (approx.  400 MB for the docker image, 200 MiB for the docker container and 4300 MiB for the volume - the downloaded exfil server in `/home/steam/exfil-dedicated/`)

### Environment Variables

Feel free to overwrite these environment variables, using -e (--env):

#### Server Configuration

```dockerfile
EXFIL_SERVER_NAME=Scordos dedicated                                             (The server name)
EXFIL_MAX_PLAYERS=32                                                            (The max. amount of players)
EXFIL_SERVER_ROLES=AdminSteamID|AdminName|Admin;ModSteamID|ModName|Moderator    (Server roles separated by ; and each entry with steamid|playername|role, where role can be Admin or Moderator)
EXFIL_SERVER_PORT=7777                                                          (The port the server is running on)
EXFIL_SERVER_QUERY_PORT=27015                                                   (The query port used by the server)
EXFIL_SERVER_PASSWORD=xyz                                                       (The optional server password)
STEAM_BETA_BRANCH=name                                                          (optional beta branch to use)
STEAM_BETA_PASSWORD=password                                                    (optional beta password to use)
```

## Customizing this Container

### Pre and Post Hooks

The container includes two scripts for executing custom actions:

* `/home/steam/exfil-dedicated/pre-serverupdate` is executed before the server is downloaded/updated by steamcmd
* `/home/steam/exfil-dedicated/pre-serverstart.sh` is executed before the exfil server starts

When using a persient volume mounted at `/home/steam/exfil-dedicated/` you may edit these scripts to perform custom actions, such as doing backups and so on.

Alternatively, you may have docker mount files from outside the container to override these files. E.g.:

```console
-v /path/to/pre-serverstart.sh:/home/steam/exfil-dedicated/pre-serverstart.sh
```

## Credits

This container leans heavily on the work of [CM2Walki](https://github.com/CM2Walki/), especially his [SteamCMD](https://github.com/CM2Walki/steamcmd) container image. GG!