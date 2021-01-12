#!/bin/bash
docker build -t myunsecureimage --build-arg SECRETPASSWORD=P@assw0rd .
docker history myunsecureimage:latest