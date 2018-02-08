#!/bin/bash
docker run -d --tty --rm -p 5000:5000 --volume "$PWD":/data cloudshowrome "$@"
