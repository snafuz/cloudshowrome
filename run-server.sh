#!/bin/bash
docker run --interactive --tty --rm -p 5000:5000 --volume "$PWD":/data cloudshowrome "$@"
