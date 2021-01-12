#!/bin/bash
#
# This file demonstrates the build of an container image, where the
# secret passed to build-args cannot be exposed via docker history command

# Build image
docker build -t mysecureimage --build-arg SECRETPASSWORD=P@assw0rd .

# Display build layer history
docker history mysecureimage:latest