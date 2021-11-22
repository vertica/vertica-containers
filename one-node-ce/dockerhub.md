
# About

This is a single-node Docker [Community Edition](https://www.vertica.com/docs/latest/HTML/Content/Authoring/GettingStartedGuide/DownloadingAndStartingVM/DownloadingAndStartingVM.htm) image for Vertica. The base OS for the image is CentOS7.9.2009 with a Vertica Version 11.0.1 CE.

# Supported Tags
* 11.0.1-0, latest
* 11.0.0-0
* 10.1.1-0

# Quick Reference

* [Official Vertica Documentation](https://www.vertica.com/docs/latest/HTML/Content/Home.htm)
* Supported architectures: `amd64`

# What is Vertica?

Vertica is a unified analytics platform, based on a massively scalable architecture with the broadest set of analytical functions spanning event and time series, pattern matching, geospatial and end-to-end in-database machine learning. Vertica enables you to easily apply these powerful functions to the largest and most demanding analytical workloads, arming you and your customers with predictive business insights faster than any analytics data warehouse in the market. Vertica provides a unified analytics platform across major public clouds and on-premises data centers and integrates data in cloud object storage and HDFS without forcing you to move any of your data.
https://www.vertica.com/

# Prerequisites
* Install [Docker](https://docs.docker.com/get-docker/)
* (Optional) Install [docker-compose](https://docs.docker.com/compose/) `v1.20` and higher for use in a multi-container environment.

# Supported Platforms

Container techology provides the freedom to run environments independently of the host operating system. This image has only been tested with CentOS. Further testing is ongoing.

# How to Use This Image

## Run a standalone docker container:
You can use `docker run`. In the following example, `vertica/vertica-ce` is the container image you pulled:

```sh
docker run -p 5433:5433 -p 5444:5444 \
           --mount type=volume,source=vertica-data,target=/data \
           --name vertica_ce \
           vertica/vertica-ce
```

In the previous command:
* `vertica_ce` is the name of the container.
* `vertica-data` is a [Docker volume](https://docs.docker.com/storage/volumes/).

The image provides the following configurations to simplify usage:
* A pre-built sample database named **VMart**
* Database user account named **dbadmin**
* Database group named **verticadba**

> **Note**: By default, there is no database password.

## Access the container:
```sh
docker exec -it <container name> bash -l
```
After you access a shell, run `/opt/vertica/bin/vsql` to connect to the database and execute vsql commands on the files and volumes mounted in the container. By default, an example schema named `VMart` is loaded into the database.

You can access a container shell and vsql with a single command:
```sh
docker exec -it <container_name> /opt/vertica/bin/vsql
```

## Access the database via vsql/client:

The `5433` and`5444` port will be mapped to your host, which means you need to leave this port unoccupied.

You can then access the database, either via vsql on the container, vsql on the host, or via an external client using the `5433` and`5444` port.

## Persisting data:
This container mounts a Docker volume named `vertica-data` in the container as a persistent data store for the Vertica database. A Docker volume is used instead of a mounted host directory for the following reasons:
* Cross-platform acceptance. Docker volumes are compatible with Linux, MacOS, and Microsoft Windows. 
* The container runs with different username to user-id mappings. A container with a mounted host directory might create files that you cannot inspect or delete because they are owned by a user that is determined by the Docker daemon. 


> **Note**: Docker volumes live on the host filesystem as directories. These directories are created automatically and stored at `/var/lib/docker/volumes/`. Each volume is stored under `./volumename/_data/`. This might limit the amount of data you can store in your database if that directory is on a small filesystem.

You may also use a bind mount to another directory that is mounted on a sufficient disk, if you dont want to use docker volumes:
```sh
docker run -p 5433:5433 -p 5444:5444\
           --mount type=bind,source=/<directory>,target=/data \
           --name vertica_ce \
           vertica/vertica-ce
```
Make sure the user running `docker run` has enough privileges to read and write the source directory.

## Use with Docker Compose:

You may use the Docker image in with docker-compose. Following is an example:
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

Run `docker-compose up`:
```sh
docker-compose --file ./docker-compose.yml --project-directory <directory_name> up -d
```

> Note: We are yet to test integration of this with other services. So, we do not have more information on network setup.


## License:
Vertica Community Edition is licensed under the [Vertica Community Edition License](https://www.vertica.com/end-user-license-agreement-ce-version/).
