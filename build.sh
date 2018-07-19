#!/bin/bash
set -ex
# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=objectsource
# image name
IMAGE=m2-clean-image
docker build -t $USERNAME/$IMAGE:latest .
