# Periodic rclone sync

A dead simple container to automatically sync one directory to another on any given interval.


## Usage

### 1. Create your rclone.conf file

Install [rclone](https://rclone.org/) on your machine.
It doesn't have to be the same machine that will be running this container - we only need to generate the configuration to access the files you want to synchronize.

*Note: this is optional if you will only be syncing local files.*

Run `rclone config` and create the remotes that you want to connect to.
After having done so, run `rclone config file`: this will output the path to the file that contains the config. Copy that.

For this example, I set up an FTP connection (`NAS`), a Google Drive connected (`My_Google_Drive`), and an encryption wrapper around the latter (`My_Encrypted_Google_Drive`).
Your file is going to look similar, but with different providers.

**rclone.conf**:
```
[NAS]
type = ftp
host = 192.168.0.1
user = services
pass = *Redacted*

[My_Google_Drive]
type = drive
client_id = *Redacted*
client_secret = *Redacted*
scope = drive.file
token = {"access_token":"*Redacted*","token_type":"Bearer","refresh_token":"*Redacted*","expiry":"2022-01-01T00:00:00.000000000+00:00"}
team_drive =

[My_Encrypted_Google_Drive]
type = crypt
remote = My_Google_Drive:
password = *Redacted*
```


### 2. Run the container

### Run it with Docker

Let's imagine that we want to sync some local files to our NAS once every hour. Here's what that'd look like:

```sh
docker run -d \
    --name=periodic-rclone-sync-local-to-nas \
    -v /path/to/rclone.conf:/config/rclone/rclone.conf \
    -v /path/to/my/files:/data \
    -e SOURCE=/data \
    -e TARGET=NAS:/files/from/my/machine \
    -e INTERVAL=60 \
    matthiasmullie/periodic-rclone-sync
```

- We pass the `rclone.conf` file (the one we generated earlier) to the container (at `/config/rclone/rclone.conf`)
- We also make our local files (in this case at `/path/to/my/files`) accessible to the container (at `/data`, but can be any path)
- We set the SOURCE to be `/data`, the same one we just made our files accessible at
- We set TARGET up to be `NAS:/files/from/my/machine`: the first part (`NAS`) is the name you'd given this provider in rclone; the second part is the path of your files on that provider
- And since we want this to be run hourly, we're going to set the INTERVAL to 60 minutes

Let's now imagine we want to back up the `/files` folder on our NAS to `/my-backup` on Google Drive, encrypted, on a daily basis.
Here's what that'd look like:

```sh
docker run -d \
    --name=periodic-rclone-sync-nas-to-gdrive \
    -v /path/to/rclone.conf:/config/rclone/rclone.conf \
    -e SOURCE=NAS:/files \
    -e TARGET=My_Encrypted_Google_Drive:/my-backup \
    -e INTERVAL=1440 \
    matthiasmullie/periodic-rclone-sync
```

- Like before, we pass `rclone.conf` to the container
- We set the SOURCE to be `NAS:/files`. The first part (`NAS`) is the name you'd given this provider in rclone; the second part is the path of your files on that provider
- Same thing with TARGET, which we're setting to `My_Encrypted_Google_Drive:/my-backup`
- And since we want this to be run daily, INTERVAL is going to be 24 * 60 = 1440 minutes

Ta-da! Your data will automatically synchronize!


#### Or run it with docker-compose

Here's the same configuration in `docker-compose.yml` format. With added health checks.

```yml
version: '3'
services:
  rclone-sync-local-to-nas:
    restart: unless-stopped
    container_name: rclone-sync-local-to-nas
    image: matthiasmullie/periodic-rclone-sync
    environment:
      - INTERVAL=60 # hourly
      - SOURCE=/data
      - TARGET=NAS:/files/from/my/machine
    volumes:
      - /path/to/rclone.conf:/config/rclone/rclone.conf
      - /path/to/my/files:/data
    healthcheck:
      test: "/bin/sh -c '[ \"$$(($$(date +%s) - $$(date +%s -r /var/log/sync.log)))\" -lt \"$$((60 * 60))\" ] && cat /var/log/sync.log | grep \"complete\"' || exit 1 && wget --spider --quiet --tries=5 --timeout=10 http://healthchecks:8000/ping/faeb8fd5-09ca-4122-839b-bb51dcc6028b || exit"
      interval: 5m
      timeout: 10s
      retries: 15
      start_period: 5m
  periodic-rclone-sync-nas-to-gdrive:
    restart: unless-stopped
    container_name: periodic-rclone-sync-nas-to-gdrive
    image: matthiasmullie/periodic-rclone-sync
    environment:
      - INTERVAL=1440 # daily
      - SOURCE=NAS:/files
      - TARGET=My_Encrypted_Google_Drive:/my-backup
    volumes:
      - /path/to/rclone.conf:/config/rclone/rclone.conf
    healthcheck:
      test: "/bin/sh -c '[ \"$$(($$(date +%s) - $$(date +%s -r /var/log/sync.log)))\" -lt \"$$((24 * 60 * 60))\" ] && cat /var/log/sync.log | grep \"complete\"' || exit 1 && wget --spider --quiet --tries=5 --timeout=10 http://healthchecks:8000/ping/faeb8fd5-09ca-4122-839b-bb51dcc6028b || exit"
      interval: 5m
      timeout: 10s
      retries: 15
      start_period: 5m
```


## Configuration

This is a dead simple thing, there isn't all that much to configure.

As mentioned before, we're using `rclone` internally for its extensive and excellent multi-provider support. Providers are to be configured via `rclone config`, and that config file then passed into this container to `/config/rclone/rclone.conf`.

Other params (all required):

* `INTERVAL`: the interval, in minutes, to run the synchronization at
* `SOURCE`: provider & path to get the data from
* `TARGET`: provider & path to sync the data to
