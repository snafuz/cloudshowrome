#!/bin/bash
#
#run api-server in interactive mode
docker run -d --tty --rm -p 5000:5000 --volume "$PWD":/data cloudshowrome "$@"
