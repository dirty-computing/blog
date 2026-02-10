#!/bin/sh

#docker run gitlab-runner register

if [ -f /runner/config.toml ]; then
    docker run --privileged --rm -d -v /runner:/etc/gitlab-runner/ -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner run
else
    docker run --privileged --rm -ti -v /runner:/etc/gitlab-runner/ -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner register
    cat /runner/config.toml
    echo ...
    sed -i 's/privileged = false/privileged = true/' /runner/config.toml
    echo ...
    cat /runner/config.toml
fi