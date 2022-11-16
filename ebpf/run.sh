#!/usr/bin/env sh

docker run --rm --pid=host --privileged=true -v $(pwd):/out -v /lib/modules:/lib/modules dgageot/ebpf /entrypoint.sh "$@"
