#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

export DOTSCIENCE_PROVIDER_VERSION=${DOTSCIENCE_PROVIDER_VERSION:="0.0.1"}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  MACHINE_TYPE=`uname -m`
  export OS="linux"
  if [ "$MACHINE_TYPE" == 'x86_64' ]; then
    export ARCH="amd64"
  else
    export ARCH="386"
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  export OS="darwin"
  export ARCH="amd64"
  
else
  echo 1>&2 "Unknown os type: $OSTYPE."
fi

echo "downloading plugin version $DOTSCIENCE_PROVIDER_VERSION for os: $OS, arch: $ARCH..."

URL="https://github.com/dotmesh-io/terraform-provider-dotscience/releases/download/${DOTSCIENCE_PROVIDER_VERSION}/terraform-provider-dotscience_${DOTSCIENCE_PROVIDER_VERSION}_${OS}_${ARCH}"
PLUGIN_DIRECTORY="$HOME/.terraform.d/plugins"
PLUGIN_FILENAME="terraform-provider-dotscience_v${DOTSCIENCE_PROVIDER_VERSION}"
PLUGIN_PATH="${PLUGIN_DIRECTORY}/${PLUGIN_FILENAME}"

if [[ -f "$PLUGIN_PATH" ]]; then
  echo "plugin version $DOTSCIENCE_PROVIDER_VERSION already downloaded"
  exit 0
fi

mkdir -p $PLUGIN_DIRECTORY
curl --fail -L -o $PLUGIN_PATH $URL
chmod a+x $PLUGIN_PATH
