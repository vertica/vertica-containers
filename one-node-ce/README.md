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

# Supported Platforms

Container techology provides the freedom to run environments independently of the host operating system. For example, you can run a CentOS container on an Ubuntu workstation, and vice versa.

Vertica provides a Dockerfile for different distributions so that you can create an containerized environment that you are the most comfortable with. This is helpful if you need to access a container shell to perform tasks, such as administering the database with [admintools](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/AdminTools/WritingAdministrationToolsScripts.htm).

## Vertica:
- 12.x
- 11.x
- 10.x

## CentOS
- 8.3
- 7.9

## Ubuntu
- 20.04
- 18.04

Vertica tests the CentOS containers most thoroughly. Vertica provides the [Dockerfile_Ubuntu](./Dockerfile_Ubuntu) for users that have only a Vertica DEB file. You can adapt that Dockerfile for recent versions of Debian.

# How to use this image

## Store the Vertica RPM or DEB

To build an image using this repository, you must store your Vertica RPM or DEB archive in the `./packages` directory.

If you do not have a Vertica archive, register to download the free [Community Edition](https://www.vertica.com/try/) (CE) license. The CE license allows you to create a three-node Vertica cluster with a maximum of 1TB of storage.

## Build the image

The repository [Makefile](./Makefile) creates an image with a [DBADMIN role](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/DBUsersAndPrivileges/Roles/PredefinedRoles.htm).

Export the following environment variables to customize image properties:

| Environment Variable | Description | Default Values |
| :--------------------| :-----------| :--------------|
| `TAG`          | Required. Image tag that represents the Vertica version. | `latest` |
| `IMAGE_NAME`   | Required. Image name. | `vertica-ce` |
| `OS_TYPE`      | Required. Operating system distribution.  | `CentOS` | 
| `OS_VERSION`   | Required. Operatoring system versions. | CentOS: `7.9.2009`<br> Ubuntu: `18.04` | 
| `VERTICA_PACKAGE` | Name of the RPM or DEB file. | CentOS: `vertica-x86_64.RHEL6.latest.rpm`<br>Ubuntu: `vertica.latest.deb` |

> **Note**: You can edit the `Makefile` defaults to custom values for your environment.
> If you do not specify `VERTICA_PACKAGE`, and `TAG` is not set to `latest`, then the `TAG` must be the Vertica version because it is used to construct the version portion of the `VERTICA_PACKAGE` name.

#### Examples

Default values:
```shell
$ make
```
Custom image name and tag:
```shell
$ make IMAGE_NAME=one-node-ce TAG=latest
```

Ubuntu base OS:
```shell
$ make
```

Custom RPM file name:
```shell
$ make VERTICA_PACKAGE=vertica-11.0.0.x86_64.RHEL6.rpm
```

### Custom build-time variables

Export the following environment variables to customize the container at build-time:

| Environment Variable | Description | Default Values |
| :--------------------| :-----------| :--------------|
| `VERTICA_DB_USER`   | OS user and implicit database [superuser](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/DBUsersAndPrivileges/Privileges/AboutSuperuserPrivileges.htm).  | `dbadmin` |
| `VERTICA_DB_UID`    | Vertica user uid.                        | `1000` |
| `VERTICA_DB_GROUP`  | Group for database administrator users.  | `verticadba` | 
| `VERTICA_DB_NAME`   | Vertica database name.                   | `VMart` | 

#### Example

```shell
$ make IMAGE_NAME=one-node-ce TAG=latest VERTICA_DB_USER=vertica VERTICA_DB_UID=1200
```
### Reducing file size

After `Dockerfile_<distro>` installs the RPM or DEB file, it runs `tools/cleanup.sh`. This script trims the size of the distribution by removing less-commonly used files, and applies other file-size reduction techniques.

## Testing the container

Test the container with the `run_tests.sh` script. You can use the `make test` target to run `run_tests.sh`, or you can run the script directly.

### run_tests.sh
The `run_tests.sh` script verifies that the container can execute Vertica and some of the additional libraries.

> **IMPORTANT**: `run_tests.sh` requires a [local copy of the vsql client](#getting-a-local-copy-of-vsql). 

The script uses the Vertica port number `5433`, so you must stop any existing Vertica server on your test system before you test your container.

The test uses your image to create a new container with a unique tag and volume. Because the test sets up the optional libraries and creates the VMart database, creating a new container can take up to three minutes.

If the tests pass, `All tests passed` is displayed at the end of the output, and the script exits with a `0` exit status. If the test fails with errors, the output contains `ERROR: <description>`, where `<description>` is a description of the error.

You can run the script with the `-k` argument to retain the container and make it available for examination after testing:

```shell
$ ./run-test.sh -k
```
When you are done with the container, you must manually remove it:

```shell
$ docker stop vertica_ce_<suffix>
$ docker rm vertica_ce_<suffix>
$ docker volume rm vertica-test-<suffix>
```
In the previous command, `<suffix>` refers to the the PID of the test-script shell that created the container and its volume. When used with the `-k` flag, `run-test.sh` prints out the above commands and populates `<suffix>`.

# Run a standalone Docker container

## Start with `start-vertica.sh`

To simplify usage, this repository provides the `start-vertica.sh` script with the following options:

```shell
Usage: ./start-vertica.sh [-c cname] [-d cid_dir] [-h] [-i img_name] [-t tag] [-v hostpath:containerdir] -V docker-volume
Options are:
 -c - specify container name (default is vertica_ce)
 -d - directory-for-cid.txt (default is the current directory)
 -h - show help
 -i image - specify image name (default is vertica-ce)
 -p port - specify a port number to use for vsql to talk to vertica
 -t tag - specify the image tag (default is latest)
 -v hostpath:containerdir - mount hostpath as containerdir in the 
        container (in addition to the data docker volume)
 -V volume - docker volume to use for the Vertica database (default is vertica-data)
```

> **NOTE**: By default, the container name is `vertica_ce`. Use this name to identify the container in your local Docker registry with commands like `docker start` and `docker stop`.

### cid.txt file

The `start-vertica.sh` script creates the **cid.txt** file, which stores the container ID within the container. By default, **cid.txt** is stored in current working directory. You can specify a directory to place the **cid.txt** file using the `-d cid_dir` option. For example, the following command places **cid.txt** in the `/home` directory:

```shell
$ start-vertica.sh -d /home
```
> **NOTE**: You must have read and write access to the `cid_dir`.

## Start with `docker run`

You can also use `docker run` to start the server instance. For example:

```shell
$ docker run -p 5433:5433 \
           --mount type=volume,source=vertica-data,target=/data \
           --name vertica_ce \
           vertica-ce:latest
```
In the previous command:
* `vertica-data` is a [Docker volume](https://docs.docker.com/storage/volumes/).
* `vertica_ce` is the name of the container.
* `vertica/vertica-ce` is the image name.

## Custom scripts

The `docker-entrypoint.sh` script can run custom scripts during startup. You must store the scripts in a local directory named `.docker-entrypoint-initdb.d` and mount it in the container filesystem in `/docker-entrypoint-initdb.d/`. Scripts are executed in lexicographical order.

Supported extensions include:
- `sql`: SQL commands executed with vsql
- `sh`: Shell scripts

The following command runs custom scripts with a [bind mount](https://docs.docker.com/storage/bind-mounts/):

```shell
$ docker run -p 5433:5433 \
           --mount type=bind,source=/tmp/.docker-entrypoint-initdb.d,target=/docker-entrypoint-initdb.d/ \
           --name vertica_ce \
           vertica-ce:latest
```

## Access the container filesystem

If you used the `start-vertica.sh` script to [start the server instance](#start-the-vertica-server-instance), use the `run-shell-in-container.sh` script to access a shell within a container. This script uses the **cid.txt** file that the `start-vertica.sh` creates to store the container ID. In the following command, `<cid_dir>` is the directory that stores **cid.txt**:

```shell
$ ./run-shell-in-container.sh [-d directory-for-cid.txt] [-n container-name] [-u uid] [-h ] [ ? ]
```

You must specify either `-d directory-for-cid.txt` or `-n container-name`. For example:

```shell
$ ./run-shell-in-container.sh -n vertica_ce
```

`-u uid` specifies the user account inside the container. Vertica recommends that you use `DBADMIN_ID` (default 1000), because that user has proper access to Vertica directories inside the container.

> **NOTE**: If you have a [local copy](#getting-a-local-copy-of-vsql) of `vsql`, you do not need to access a container shell unless you need to use [admintools](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/AdminTools/WritingAdministrationToolsScripts.htm).

### Access with `docker exec`
Alternatively, access a shell in the container with `docker exec`. `docker exec` requires that you provide the container name:

```shell
$ docker exec -it <container name> bash -l
```

### Connect to the databse
After you access a shell, run `/opt/vertica/bin/vsql` to connect to the database and execute `vsql` commands on the files and volumes mounted in the container. For example:
```shell
$ docker exec -it <container_name> /opt/vertica/bin/vsql
```

## View container logs

Fetch the container logs with `docker logs`. The following command uses [cid.txt](#cidtxt-file):

```shell
$ docker logs `cat cid.txt`
```
Fetch the logs for a container named **vertica_ce**:

```shell
$ docker logs vertica_ce
```
## Stop the container

Stop the container with `docker stop`. The following command uses [cid.txt](#cidtxt-file):

```shell
$ docker stop `cat cid.txt`
```
The following command stops a container named **vertica_ce**:

```shell
$ docker logs vertica_ce
```

# Access the database with vsql or external client

The container exposes port 5433 for external client access. To access the database from outside the container, you must have a [local copy of the vsql client](#getting-a-local-copy-of-vsql).

## Getting a local copy of vsql

See [Client Drivers](https://www.vertica.com/download/vertica/client-drivers/) in to download all available client drivers.

## Access the database

By default, the Dockerfile creates the `dbadmin` user in the container database. The following command accesses the database:
```shell
$ vsql -U dbadmin
```
You can configure the database user name with the `vertica_db_user` ARG variable in the Dockerfile or when you [build the image](#custom-build-time-variables).

## Persisting data

This container mounts a [Docker volume](https://docs.docker.com/storage/volumes/) named `vertica-data` in the container to persist data for the Vertica database. A Docker volume is used instead of a mounted host directory for the following reasons:
* Cross-platform acceptance. Docker volumes are compatible with Linux, MacOS, and Microsoft Windows. 
* The container runs with different username to user-id mappings. A container with a mounted host directory might create files that you cannot inspect or delete because they are owned by a user that is determined by the Docker daemon. 

> **Note**: A Docker volume is represented on the host filesystem as a directory. These directories are created automatically and stored at `/var/lib/docker/volumes/`. Each volume is stored under `./volumename/_data/`. A small filesystem might might limit the amount of data you can store in your database.

## Extending the image

The `dbadmin` user environment is extended to be user-friendly. For details, see the [vertica_env.sh](env_setup/vertica_env.sh) and [.vsqlrc](env_setup/.vsqlrc) scripts.

## Runtime configuration

To configure the Vertica container during runtime, inject environment variables when when you execute `docker run`:
```shell
$ docker run -p 5433:5433 -d \
  -e TZ='Europe/Prague' \
  vertica-ce:latest
```
The following table contains configurable environment variable parameters:

| Environment Variable | Description | 
| :--------------------| :-----------|
| `APP_DB_USER` | Name of a database user, in addition to `vertica_db_user`. This user is created only when this variable is set. By default, this user is assigned [pseudosuperuser](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/DBUsersAndPrivileges/Roles/PSEUDOSUPERUSERRole.htm) privileges. |
| `APP_DB_PASSWORD` | Password for `APP_DB_USER`. If this is omitted, the password is empty. |
| `TZ`: "${VERTICA_CUSTOM_TZ:-Europe/Prague}" | The database time zone.<br><br>**IMPORTANT**: Vertica does not contain all timezones. Each Dockerfile contains a  commented-out workaround solution that begins "Link OS timezones". Uncomment the workaround to use time zones.<br>Setting the time zone with VERTICA_CUSTOM_TZ enables you to override it from your environment. |
| `DEBUG_FAILING_STARTUP` | For development purposes. When you set the value to `y`, the entrypoint script does not end in case of failure, so you can investigate any failures. |

# References and Contributions

Thanks to [gooddata](https://github.com/gooddata/docker-image-for-vertica) for providing the implementation on which this work is based.