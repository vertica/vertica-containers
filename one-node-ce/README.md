[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](https://opensource.org/licenses/Apache-2.0)

# Running Vertica with Docker

[Vertica](https://www.vertica.com/) is a massively scalable analytics data warehouse that stores your data and performs analytics on it all in one place.

This Dockerfile creates a single-node container using the [Vertica Community Edition](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/DownloadingAndStartingVM/DownloadingAndStartingVM.htm) (CE) license. The CE license includes:
- [VMart example database](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/IntroducingVMart/IntroducingVMart.htm)
- Admintools
- vsql
- Developer libraries

## Prerequisites
Install [Docker Desktop](https://www.docker.com/get-started) or [Docker Engine](https://docs.docker.com/engine/install/).

## Supported Platforms

Container techology provides the freedom to run environments independently of the host operating system. For example, you can run a CentOS container on an Ubuntu workstation, and vice versa.

Vertica provides a Dockerfile for different distributions so that you can create an containerized environment that you are the most comfortable with. This is helpful if you need to access a container shell to perform tasks, such as administering the database with [admintools](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/AdminTools/WritingAdministrationToolsScripts.htm).

### Vertica:
- 11.x
- 10.x (beta)

### CentOS
- 8.3
- 7.9

### Ubuntu
- 20.04
- 18.04

Vertica tests the CentOS containers most thoroughly.  Dockerfile_Ubuntu is provided for those who have a Vertica .deb file instead of a Vertica .rpm file, and can be adapted for recent versions of Debian.

## Building the image

### Store the Vertica RPM or DEB

To build an image using this repository, you must store your Vertica RPM or DEB archive in the `./packages` directory.

If you do not have a Vertica RPM, register to download the free [Community Edition](https://www.vertica.com/try/) license. This is a limited license that allows you to create a three-node Vertica cluster with a maximum of 1TB of storage.

### Build the image with `Makefile`
Vertica provides the `Makefile` script that creates an image with a [DBADMIN role](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/DBUsersAndPrivileges/Roles/PredefinedRoles.htm).

The following variables can be exported to customize the image properties.

| Environment Variable | Description | Default Values |
| :--------------------| :-----------| :--------------|
| TAG          | Required tag of the image. | latest |
| IMAGE_NAME   | Required name of the image.| vertica-ce |
| OS_TYPE      | Required OS Type.          | CentOS | 
| OS_VERSION   | Required OS versions.      | CentOS: 7.9.2009<br> Ubuntu: 18.04 | 
| VERTICA_PACKAGE | Name of the .rpm or .deb file | CentOS: vertica-x86_64.RHEL6.latest.rpm<br>Ubuntu: vertica.latest.deb |

The defaults may not be suitable for your site, you may want to edit the `Makefile` to use more appropriate defaults.

If you don't specify a VERTICA_PACKAGE, and the TAG is not
'latest' then the TAG is expected to be the vertica version and used
to construct the VERTICA_PACKAGE name

#### Examples:
```shell
# Builds image with default values.
make 

# Builds image with custom image name and tag.
make IMAGE_NAME=one-node-ce TAG=latest

# Build image with Ubuntu base OS.
make OS_TYPE=Ubuntu Tag=latest  

# Build image with a non-default filename for the rpm.
make VERTICA_PACKAGE=vertica-11.0.0.x86_64.RHEL6.rpm
```

### Build Custom image

To customize build-time variables including the default database user, and group, and database name, export following optional variables:

| Environment Variable | Description | Default Values |
| :--------------------| :-----------| :--------------|
| VERTICA_DB_USER   | OS user and implicit database [superuser](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/DBUsersAndPrivileges/Privileges/AboutSuperuserPrivileges.htm).  | dbadmin |
| VERTICA_DB_UID    | Vertica user uid.                        | 1000 |
| VERTICA_DB_GROUP  | Group for database administrator users.  | verticadba | 
| VERTICA_DB_NAME   | Vertica database name.                   | VMart | 

#### Example:
```shell
make IMAGE_NAME=one-node-ce TAG=latest VERTICA_DB_USER=vertica VERTICA_DB_UID=1200
```

After `Dockerfile_<distro>` installs the RPM or DEB file, it runs `tools/cleanup.sh`. `tools/cleanup.sh` trims the size of the distribution by removing less-commonly used files, and applies other file-size reduction techniques.

# Testing with ./run_tests.sh

Once you have built your container, you can test it using the `./run_tests.sh` script (or by running `make test`).

The `./run_tests.sh` script verifies that the container can execute Vertica and some of the additional libraries. This script requires a [local copy of the vsql client](#getting-a-local-copy-of-vsql). 

Before you test your container, you must stop any existing Vertica server (container or otherwise) on your test system because the `./run_tests.sh` script uses the normal Vertica port number.

The test uses your image to create a new container with a unique tab, and volume. Because the test sets up the optional libraries and creates the VMart database, creating a new container can take as long as three minutes.

If the tests pass, "All tests passed" appears at the end of the output, and the script exits with a 0 exit status. If the test fails with errors, the output contains `ERROR: <description>`, where `<description>` is a description of the error.

You can run the script with the `-k` argument to retain the container and make it available for examination:

```shell
./run-test.sh -k
```

When you are done with the container, you must manually remove it:

```shell
docker stop vertica_ce_<suffix>
docker rm vertica_ce_<suffix>
docker volume rm vertica-test-<suffix>
```
In the previous command, `<suffix>` refers to the numeric suffix (the PID of the test-script shell that created the container and its volume). When used with the `-k` flag, `run-test.sh` prints out the above commands with `<suffix>` filled in.

## How to use this image

### Start the Vertica server instance

Vertica provides the `start-vertica.sh` script with the following options:

```shell
Usage: ./start-vertica.sh [-c cname] [-d cid_dir] [-h] [-i img_name] [-t tag] [-v hostpath:containerdir] -V docker-volume
Options are:
 -c - specify container name (default is vertica_ce)
 -d - directory-for-cid.txt (default is the current directory)
 -h - show help
 -i image - specify image name (default is vertica-ce)
 -t tag - specify the image tag (default is latest)
 -v hostpath:containerdir - mount hostpath as containerdir in the 
        container (in addition to the data docker volume)
 -V volume - docker volume to use for the Vertica database (default is vertica-data)
```

**NOTE**: By default, the container name is `vertica_ce`. Use this name to identify the container in your local Docker registry, with commands like `docker start` and `docker stop`.

#### cid.txt file

The `start-vertica.sh` script creates the **cid.txt** file, which stores the container ID within the container. By default, **cid.txt** is stored in current working directory. You can specify a directory to place the **cid.txt** file using the `-d cid_dir` option. For example, the following command places **cid.txt** in the home directory:

```shell
start-vertica.sh -d /home
```
**NOTE**: You must have read and write access to the `cid_dir`.

### Start with `docker run`

You can also use `docker run`. In the following example, `vertica-ce:latest` is the container image you created in [Building the image](#building-the-image):

```shell
docker run -p 5433:5433 \
           --mount type=volume,source=vertica-data,target=/data \
           --name vertica_ce \
           vertica-ce:latest
```


### Custom scripts

The entrypoint script can run custom scripts during startup. You must store the scripts in a local directory named `.docker-entrypoint-initdb.d`. To make these scripts accessible by the entrypoint script, mount this directory in the container filesystem in `/docker-entrypoint-initdb.d/`. Scripts are executed in lexicographical order.

Supported extensions include:
- `sql`: SQL commands executed with vsql
- `sh`: Shell scripts

The following command creates a bind mount:

```shell
docker run -p 5433:5433 \
           --mount type=bind,source=/tmp/.docker-entrypoint-initdb.d,target=/docker-entrypoint-initdb.d/ \
           --name vertica_ce \
           vertica-ce:latest
```

For more information, see [Use bind mounts](https://docs.docker.com/storage/bind-mounts/) in the Docker documentation.

### Container shell access

If you used the `start-vertica.sh` script to [start the server instance](#start-the-vertica-server-instance), use the `run-shell-in-container.sh` script to access a shell within a container. This script uses the **cid.txt** file that the `start-vertica.sh` creates to store the container ID. In the following command, `<cid_dir>` is the directory that stores **cid.txt**:

```shell
./run-shell-in-container.sh [-d directory-for-cid.txt] [-n container-name] [-u uid] [-h ] [ ? ]
```

One needs to specify either `-d directory-for-cid.txt` or `-n container-name` (e.g., `-n vertica_ce`).

`-u uid` specifies what user runs inside the container --- you probably want to use DBADMIN_ID (default 1000), since that user has proper access to Vertica directories inside the container.

**NOTE**: If you have a [local copy](#getting-a-local-copy-of-vsql) of `vsql`, you do not need to access a container shell unless you need to use [admintools](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/AdminTools/WritingAdministrationToolsScripts.htm).

Alternately, use the `docker exec` command to access a shell in the container. Using `docker exec` requires that you provide the container name:

```shell
docker exec -it <container name> bash -l
```

After you access a shell, run `/opt/vertica/bin/vsql` to connect to the database and execute `vsql` commands on the files and volumes mounted in the container.

You can access a container shell and vsql with a single command: 

```shell
docker exec -it <container_name> /opt/vertica/bin/vsql
```

### View container logs

You can use **cid.txt** with the `docker logs` command:

```shell
docker logs `cat cid.txt`
```
... or use the container name to view the logs. For example, the following command fetches the logs for a container named **vertica_ce**:

```shell
docker stop vertica_ce
```
### Stop the container

You can use **cid.txt** with the `docker stop` command:

```shell
docker stop `cat cid.txt`
```
... or stop the container using the container name. For example, the following command stops a container named **vertica_ce**:

```shell
docker logs vertica_ce
```

## External database access

The container exposes port 5433 for external client access. To access the database from outside the container, you must have a local copy of vsql.

### Getting a local copy of vsql

See [Client Drivers](https://www.vertica.com/download/vertica/client-drivers/) in Vertica Downloads to download all available client drivers.

#### Accessing the database

By default, the Dockerfile creates the `dbadmin` user in the container database. The following command accesses the database:
```shell
vsql -U dbadmin
```
You can configure the database user name with the `vertica_db_user` ARG variable in the Dockerfile or when you [build the custom image](#build-custom-image).

## Persisting data

This container mounts a Docker volume named **vertica-data** in the container as a persistent data store for the Vertica database. A Docker volume is used instead of a mounted host directory for the following reasons:

- Cross-platform acceptance. Docker volumes are compatible with Linux, MacOs, and Microsoft Windows.
- The container runs with different username to user-id mappings. A container with a mounted host directory might create files that you cannot inspect or delete because they are owned by a user that is determined by the Docker daemon.

For details about managing volumes, see the [Docker documentation](https://docs.docker.com/storage/volumes/).

**NOTE**: Docker volumes live on the host filesystem as directories. These directories are created automatically and stored at `/var/lib/docker/volumes/`. Each volume is stored under `./volumename/_data/`. This might limit the amount of data you can store in your database if that directory is on a small filesystem.

## Extend the image

The `dbadmin` user environment is extended to be user-friendly. For details, see the [vertica_env.sh](env_setup/vertica_env.sh) and [.vsqlrc](env_setup/.vsqlrc) scripts.

### Environment variables

To configure various aspects of Vertica in container runtime, inject corresponding environment variables when executing the `docker run` command:
```shell
docker run -p 5433:5433 -d \
  -e TZ='Europe/Prague' \
  vertica-ce:latest
```
The following table contains configurable environment variable parameters:

| Environment Variable | Description | 
| :--------------------| :-----------|
| APP_DB_USER | Name of a database user, in addition to `vertica_db_user`. This user is created only when this variable is set. by default, this user receives [pseudosuperuser](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/DBUsersAndPrivileges/Roles/PSEUDOSUPERUSERRole.htm) privileges. |
| APP_DB_PASSWORD | Password for APP_DB_USER. If this is omitted, the password is empty. |
| TZ: "${VERTICA_CUSTOM_TZ:-Europe/Prague}" | The database time zone.<br>**IMPORTANT**: Vertica does not contain all timezones. There is a commented-out workaround solution in each Dockerfile that begins "Link OS timezones". Uncomment the workaround to use time zones.<br>Setting the time zone with VERTICA_CUSTOM_TZ enables you to override it from your environment. |
| DEBUG_FAILING_STARTUP | For development purposes. When you set the value to **y**, the entrypoint script does not end in case of failure, so you can investigate any failures. |

## References and Contributions

Thanks to [gooddata](https://github.com/gooddata/docker-image-for-vertica) for providing the implementation on which this work is based.
