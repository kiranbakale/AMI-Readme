#!/usr/bin/env bash

################################################
# Small script to update frozen dependencies
################################################

set -euo pipefail
IFS=$'\n\t'

cd "$(dirname "${BASH_SOURCE[0]}")/../ansible/requirements"

[[ "${VIRTUAL_ENV:-}" != "" ]] || {
  echo "Please configure a virtual environment as per docs/environment_configure.md"
  echo "..then run \`. ./get-python-env/bin/activate\`"
  exit 1
}

pip install -r ansible-python-packages.txt
(
  echo "###########################################"
  echo "# Do not update manually"
  echo "# Run bin/freeze-dependencies.sh to update"
  echo "# Packages must target Python 3.8"
  echo "###########################################"
  pip freeze
)>requirements.txt
