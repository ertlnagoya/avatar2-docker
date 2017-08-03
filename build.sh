#!/bin/sh
IMAGE="eurecom-s3/avatar2"
docker build -t $IMAGE .
docker tag $IMAGE $IMAGE:$(git rev-parse --short HEAD)