# Vulcan Core Compose
`docker-compose` to play with `Vulcan Core` without knowing the internals.

## Abstract
This docker-compose aims to reduce as much as possible specific knowledge required to run Vulcan in your computer in order to:
- Check if fits your requirements as security scanner tool
- Maker easier for developers code and test new features or security checks

[![asciicast](https://asciinema.org/a/328346.svg)](https://asciinema.org/a/328346)

## Requirements
- [Docker](https://docs.docker.com/desktop/)

## How to use
Run vulcan-core:
```bash
git clone git:github.com:adevinta/vulcan-core-compose.git
cd vulcan-core-compose
docker-compose build
docker-compose up -d
```

This is how `docker-compose ps` should look like if everything went well:
```bash
# docker-compose ps

              Name                             Command                       State                    Ports
--------------------------------------------------------------------------------------------------------------------
vulcan-core-compose_agent_1         ./run.sh                         Up
vulcan-core-compose_bootstrap_1     ./run.sh                         Exit 0
vulcan-core-compose_events_1        /goaws                           Up                      0.0.0.0:4100->4100/tcp
vulcan-core-compose_insights_1      /aws-s3-proxy                    Up                      0.0.0.0:8088->80/tcp
vulcan-core-compose_minio_1         /opt/bitnami/scripts/minio ...   Up (health: starting)   0.0.0.0:9000->9000/tcp
vulcan-core-compose_persistence_1   sh -c apk add postgresql-c ...   Up (health: starting)   0.0.0.0:3000->80/tcp
vulcan-core-compose_postgres_1      docker-entrypoint.sh postgres    Up                      0.0.0.0:32771->5432/tcp
vulcan-core-compose_results_1       sh -c apk add curl; ./run.sh     Up (health: starting)   0.0.0.0:8081->80/tcp
vulcan-core-compose_stream_1        sh -c apk add postgresql-c ...   Up (health: starting)   0.0.0.0:8085->80/tcp
vulcan-core-compose_tools_1         ./run.sh                         Up
```

Run [vulcan-agent](https://github.com/adevinta/vulcan-agent) in your computer:

```bash
# You can get a compiled version of vulcan-agent
# from one of the containers build in the docker-compose.

# Linux:
docker cp vulcan-core-compose_agent_1:/agent/vulcan-agent-linux /tmp/vulcan-agent

# MacOS:
docker cp vulcan-core-compose_agent_1:/agent/vulcan-agent-darwin /tmp/vulcan-agent

# Export fake AWS credentials
export AWS_ACCESS_KEY_ID=fake
export AWS_SECRET_ACCESS_KEY=fake
# Run vulcan-agent
/tmp/vulcan-agent config/vulcan-agent/config.toml

# Note: If you are running in Linux you might need to edit config/vulcan-agent/config.toml and remove the following line:
#     iname = "en0"
```

**Done!** You are ready to scan some resources!

Here are some scan examples:
```bash
# Scan a Docker image using trivy scanner
docker exec -it vulcan-core-compose_tools_1 \
  /tools/scan.sh "registry.hub.docker.com/library/python:3.4-alpine" "vulcan-trivy"

# Scan example.com with some checks
docker exec -it vulcan-core-compose_tools_1 \
  /tools/scan.sh "example.com" "vulcan-http-exposed-resources;vulcan-certinfo;vulcan-tls"

# Scan example.com with all available checks
# This option may be suboptimal as some checks are not meant
# to run agains hostnames or domain names such as example.com
docker exec -it vulcan-core-compose_tools_1 \
  /tools/scan.sh "example.com" "all"

# Scan example.com and a docker image with some checks
docker exec -it vulcan-core-compose_tools_1 \
  /tools/scan.sh "example.com;registry.hub.docker.com/library/python:3.4-alpine" \
  "vulcan-http-exposed-resources;vulcan-certinfo;vulcan-tls;vulcan-trivy"
```

## Extended instructions

Simplified (yes, a bit) view of Vulcan Core:
```
                                               +--------------+
                                   +-----------+   REGISTRY   |
                                   |           +--------------+
                                   |
             +--------------+      +
       +---->+    QUEUE     +--+   |           +--------------+
       |     +--------------+  |   +    +----->+   TARGET/S   |
       |                       |   |    |      +--------------+
       |                       |   |    |
       |                       |   |    |
+------+-------+            +--v---v----+--+
| PERSISTENCE  +<-----------+    AGENT     |
+------+-------+            +--+--------+--+
       |                       |        |
       v                       |        |
 +-----+------+                |        |      +--------------+
 | POSTGRESQL |                |        +----->+   RESULTS    |
 +-----+------+                |               +------+-------+
       ^                       |                      |
       |                       |                      v
+------+-------+               |               +------+-------+
|    STREAM    +<--------------+               |    BUCKET    |
+--------------+                               +--------------+
```

The diagram above shows how Vulcan Core plug all its components in a simplified way.  
In the docker-compose there are some containers that can be easily linked to a box in the diagram by its name and there are some others that are just "helper containers" with some pre-work done so you don't need worry about how to compile the tool, etc.  

However, this is the list of components, tools and configurations done to run the docker-compose as in the example seamless.

```bash
docker-compose ps --services
```
- [persistence](https://github.com/adevinta/vulcan-persistence)
- [results](https://github.com/adevinta/vulcan-results)
- [stream](https://github.com/adevinta/vulcan-stream)
- [agent](https://github.com/adevinta/vulcan-agent)  
Agent container does not expose any endpoint but contains the compiled version of vulcan-agent binaries for linux and mac.
- [postgres](https://hub.docker.com/_/postgres)
- [minio](https://github.com/bitnami/bitnami-docker-minio)  
We are using `minio` to emulate AWS S3 service.
- [events](https://github.com/p4tin/goaws)  
We are using `goaws` to emulate AWS SQS and SNS services.
- [insights](https://github.com/pottava/aws-s3-proxy)  
We are using `aws-s3-proxy` to expose minio bucket content through HTTP.
- [bootstrap](bootstrap/run.sh)  
This container run some `configurations` required in `vulcan-persistence` in order to have everything up and ready so a vulcan-agent can connect run checks and report results seamless.  
These configurations are setup [check job queues](bootstrap/jobqueues/generic.json) and provision a [a list of checks](bootstrap/checks/).  
This list doesn't try to provide [all available checks](https://github.com/adevinta/vulcan-checks) but a starting point and some examples you can see how to add/remove checks as you wish.
- tools  
In this container we provide two Vulcan cli tools: [vulcan-core-cli](https://github.com/adevinta/vulcan-core-cli) and [security-overview](https://github.com/adevinta/security-overview) and a [shell script](tools/scan.sh) that applies some logic in order to chain the tools and generate what we call a `Vulcan Report`.


There are some more configurations to take into account in order to squeeze Vulcan to me max.  
For example, there are some checks such as `vulcan-nessus` or `vulcan-wpscan` that `requires some variables` to be exported so `vulcan-agent` can provide this info to the checks an run accordingly.

Once you are familiarised with the environment we recommend you to review the [configurations for every component](config/).

Feel free to report [issues or suggestions](https://github.com/adevinta/vulcan-core-compose/issues).
