#!/bin/sh
IMAGE="eurecom-s3/avatar2"
docker build --force-rm=true -t $IMAGE .
docker tag $IMAGE $IMAGE:$(git rev-parse --short HEAD)
