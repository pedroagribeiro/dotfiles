#!/usr/bin/env bash

#set -Eeuo pipefail

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

ask_for_sudo

sudo apt install docker.io
# install_package docker

sudo apt install docker-compose
# install_package docker-compose

execute "sudo usermod -aG docker ${USER}" "Adding docker to usergroup..."
