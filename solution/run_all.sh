#!/bin/bash
docker build -t mysecureimage --build-arg SECRETPASSWORD=P@assw0rd .
docker history mysecureimage:latest