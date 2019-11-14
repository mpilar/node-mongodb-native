#!/bin/bash
set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

NODE_LTS_NAME=${NODE_LTS_NAME:-carbon}
NODE_ARTIFACTS_PATH="${PROJECT_DIRECTORY}/node-artifacts"
NPM_CACHE_DIR="${NODE_ARTIFACTS_PATH}/npm"
NPM_TMP_DIR="${NODE_ARTIFACTS_PATH}/tmp"

# create node artifacts path if needed
mkdir -p ${NODE_ARTIFACTS_PATH}
mkdir -p ${NPM_CACHE_DIR}
mkdir -p "${NPM_TMP_DIR}"

install_dependencies() {
  # this needs to be explicitly exported for the nvm install below
  export NVM_DIR="${NODE_ARTIFACTS_PATH}/nvm"

  # install Node.js
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
  [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
  nvm install --lts=${NODE_LTS_NAME}
}

install_dependencies_windows() {
  NODE_LTS_NAME=${NODE_LTS_NAME:-carbon}
  NODE_VERSION=$(curl -s -L https://nodejs.org/dist/latest-${NODE_LTS_NAME}/SHASUMS256.txt | grep -oP 'node-v\K\w+.\w+.\w+' | head -1)

  # install Node.js
  export NVM_HOME="C:\cygwin\home\Administrator\nvm"
  export NVM_SYMLINK="C:\cygwin\home\Administrator\nvm\bin"
  export PATH=`cygpath $NVM_SYMLINK`:`cygpath $NVM_HOME`:$PATH

  curl -L https://github.com/coreybutler/nvm-windows/releases/download/1.1.7/nvm-noinstall.zip -o nvm.zip
  unzip -d ${NVM_HOME} nvm.zip
  rm nvm.zip

  chmod 777 ${NVM_HOME}
  chmod -R a+rx ${NVM_HOME}

  cat <<EOT >> ${NVM_HOME}/settings.txt
root: ${NVM_HOME}
path: ${NVM_HOME}\bin
EOT

  nvm install $NODE_VERSION
  nvm use $NODE_VERSION
}

# This loads the `get_distro` function
. $DRIVERS_TOOLS/.evergreen/download-mongodb.sh
get_distro

case "$DISTRO" in
  cygwin*)
    install_dependencies_windows
    ;;

  *)
    install_dependencies
    ;;
esac

# setup npm cache in a local directory
cat <<EOT > .npmrc
devdir=${NPM_CACHE_DIR}/.node-gyp
init-module=${NPM_CACHE_DIR}/.npm-init.js
cache=${NPM_CACHE_DIR}
tmp=${NPM_TMP_DIR}
registry=https://registry.npmjs.org
EOT

# NOTE: registry was overridden to not use artifactory, remove the `registry` line when
#       BUILD-6774 is resolved.

# install node dependencies
npm install
