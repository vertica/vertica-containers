
# About

This is a single-node Docker image of the [Vertica Community Edition](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/DownloadingAndStartingVM/DownloadingAndStartingVM.htm).

# Supported Tags

Vertica tags each container with the version number in the format _`<major>.<minor>.<patch>-<hotfix>`_. For example, `11.1.0-0` is the tag for Vertica version 11.1, service pack 0, hotfix 0. The `latest` tag is the most recently released version of Vertica.

For a comprehensive list, see [Tags](https://hub.docker.com/r/opentext/vertica-ce/tags).

# Quick Reference

* [Vertica Documentation](https://www.vertica.com/docs/latest/HTML/Content/Home.htm)
* Supported architectures: `amd64`

# What is Vertica?

Vertica is a unified analytics platform, based on a massively scalable architecture with the broadest set of analytical functions spanning event and time series, pattern matching, geospatial and end-to-end in-database machine learning. Vertica enables you to easily apply these powerful functions to the largest and most demanding analytical workloads, arming you and your customers with predictive business insights faster than any analytics data warehouse in the market. Vertica provides a unified analytics platform across major public clouds and on-premises data centers and integrates data in cloud object storage and HDFS without forcing you to move any of your data.  

https://www.vertica.com/

# Prerequisites
* Install [Docker](https://docs.docker.com/get-docker/)
* (Optional) Install [docker-compose](https://docs.docker.com/compose/) `v1.20` and higher for use in a multi-container environment.

# Supported Platforms

This image has been tested with CentOS. Further testing is ongoing.

# How to Use This Image

To simplify usage, this image provides the following configurations:
- [VMart example database](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/IntroducingVMart/IntroducingVMart.htm)
* [DBADMIN](https://www.vertica.com/docs/latest/HTML/Content/Authoring/AdministratorsGuide/DBUsersAndPrivileges/Roles/PredefinedRoles.htm) database user account
* `verticadba` database group

> **Note**: By default, there is no database password.

## Run a standalone Docker container

Start a container with `docker run`:

```sh
$ docker run -p 5433:5433 -p 5444:5444 \
           --mount type=volume,source=vertica-data,target=/data \
           --name vertica_ce \
           vertica/vertica-ce
```

In the preceding command:
* `vertica-data` is a [Docker volume](https://docs.docker.com/storage/volumes/).
* `vertica_ce` is the name of the container.
* `vertica/vertica-ce` is the image name.


## Access the container filesystem

Open a `bash` shell in a running container:
```sh
$ docker exec -it <container name> bash -l
```
After you access a shell, run `/opt/vertica/bin/vsql` to connect to the database and execute vsql commands on the files and volumes mounted in the container. By default, an example schema named `VMart` is loaded into the database.

Access a container shell and vsql with a single command:
```sh
$ docker exec -it <container_name> /opt/vertica/bin/vsql
```

## Access the database with vsql or external client

The `5433` and`5444` ports are mapped to your host, so leave these ports unoccupied.

You can then access the database in one of the following ways:
- vsql on the container
- vsql on the host
- An external client using the `5433` and`5444` port

# Persistence

This container mounts a [Docker volume](https://docs.docker.com/storage/volumes/) named `vertica-data` to persist data for the Vertica database. A Docker volume provides the following advantages over a mounted host directory:
* Cross-platform acceptance. Docker volumes are compatible with Linux, MacOS, and Microsoft Windows. 
* The container runs with different username to user-id mappings. A container with a mounted host directory might create files that you cannot inspect or delete because they are owned by a user that is determined by the Docker daemon. 

> **Note**: A Docker volume is represented on the host filesystem as a directory. These directories are created automatically and stored at `/var/lib/docker/volumes/`. Each volume is stored under `./volumename/_data/`. A small filesystem might might limit the amount of data you can store in your database.

## Bind mounts

As an alternative to a Docker volume, you can use a [bind mount](https://docs.docker.com/storage/bind-mounts/) to persist data to another directory with sufficient disk space:
```sh
$ docker run -p 5433:5433 -p 5444:5444\
           --mount type=bind,source=/<directory>,target=/data \
           --name vertica_ce \
           vertica/vertica-ce
```
> **Important**: The user that executes `docker run` must have read and write privileges on the source directory.

# Docker Compose

Define a multi-container application with a `docker-compose` YAML file. For example:
```yaml
version: "3.9"
services:
  vertica:
    environment:
      APP_DB_USER: "newdbadmin"
      APP_DB_PASSWORD: "vertica"
      TZ: "Europe/Prague"
    container_name: vertica-ce
    image: vertica/vertica-ce
    ports:
      - "5433:5433"
      - "5444:5444"
    deploy:
      mode: global
    volumes:
      - type: volume
        source: vertica-data2
        target: /data
volumes:
  vertica-data2:
```

To run the configuration, run `docker-compose up`:
```sh
$ docker-compose --file ./docker-compose.yml --project-directory <directory_name> up -d
```
> **Note**: The Docker Compose integration is not tested, so there are no network setup recommendations.


# License

View the [license information](https://www.microfocus.com/en-us/legal/software-licensing) for this image.
