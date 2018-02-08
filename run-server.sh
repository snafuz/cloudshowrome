#!/bin/bash
#
#run the server as daemon use docker ps to see the status
docker run -d --tty --rm -p 5000:5000 --volume "$PWD":/data cloudshowrome "$@" > .apiserver.pid
