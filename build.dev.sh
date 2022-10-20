#! /bin/bash

export COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1
docker-compose -f "docker-compose.dev.yml" -p svt--development down --remove-orphans
docker-compose -f "docker-compose.dev.yml" -p svt--development build --force-rm
docker-compose -f "docker-compose.dev.yml" -p svt--development up -d