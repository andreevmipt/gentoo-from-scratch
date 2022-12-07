# gentoo-python38 with utils and gcc with tox and configured Artifactory PiPI repository
gcc добавлен из-за ошибки  libgcc_s.so.1 must be installed for pthread_cancel to work - возможно можно как-то обойти
toolchain (binutils gcc linux-headers) необходимы для сборки некоторых эксперементальных пакетов (shap например)

Скрипт сборки использует # syntax = docker/dockerfile:1.0-experimental
запуск
DOCKER_BUILDKIT=1 nohup  docker -v build -t artifactory.host:5000/docker-local/gentoo-py38-tox:1.2 . 2>&1 > build-amd64.log &
nohup docker buildx build -t artifactory.host:5000/docker-local/gentoo-py38-tox-odbc:1.2 . 2>&1 > build-amd64.log &

hardened profile
DOCKER_BUILDKIT=1 nohup  docker -v build -t artifactory.host:5000/docker-local/gentoo-py38-tox:1.2  -f ./Dockerfile_hardened . 2>&1 > build-amd64.log &

В ubuntu/mint требуется удалить  sudo dpkg --remove --force-depends golang-docker-credential-helpers для кастомного докер-репозитория
https://github.com/docker/docker-credential-helpers/issues/60

## for local experiments 
docker create -v /usr/portage --name myportagesnapshot gentoo/portage:latest /bin/true
docker run --interactive --tty --volumes-from myportagesnapshot gentoo/stage3-amd64:latest /bin/bash

# inspired by
https://github.com/ismell/gentoo-docker-images

# обновление дерева портажей
TARGET=portage ./build.sh

## TODO
+добавить bpf фреймворк для трейсинга python приложений 
 
