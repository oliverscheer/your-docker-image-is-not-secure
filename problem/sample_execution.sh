#!/bin/bash
#
# This file demonstrates the build of an container image that contains
# a secret that can be retrieved via docker history command

# Build image
docker build -t myunsecureimage --build-arg SECRETPASSWORD=P@assw0rd .

# Display build layer history
docker history myunsecureimage:latest