#!/bin/bash
# set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

# Supported/used environment variables:
#       AUTH                    Set to enable authentication. Defaults to "noauth"
#       SSL                     Set to enable SSL. Defaults to "nossl"
#       UNIFIED                 Set to enable the Unified SDAM topology for the node driver
#       MONGODB_URI             Set the suggested connection MONGODB_URI (including credentials and topology info)
#       MARCH                   Machine Architecture. Defaults to lowercase uname -m

AUTH=${AUTH:-noauth}
SSL=${SSL:-nossl}
UNIFIED=${UNIFIED:-}
MONGODB_URI=${MONGODB_URI:-}

# This loads the `get_distro` function
. $DRIVERS_TOOLS/.evergreen/download-mongodb.sh
get_distro

case "$DISTRO" in
  cygwin*)
    export NVM_HOME="C:\cygwin\home\Administrator\nvm"
    export NVM_SYMLINK="C:\cygwin\home\Administrator\nvm\bin"
    export PATH=`cygpath $NVM_SYMLINK`:`cygpath $NVM_HOME`:$PATH
    ;;

  *)
    export PATH="/opt/mongodbtoolchain/v2/bin:$PATH"
    NODE_ARTIFACTS_PATH="${PROJECT_DIRECTORY}/node-artifacts"
    export NVM_DIR="${NODE_ARTIFACTS_PATH}/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    ;;
esac

# run tests
echo "Running $AUTH tests over $SSL, connecting to $MONGODB_URI"
MONGODB_UNIFIED_TOPOLOGY=${UNIFIED} MONGODB_URI=${MONGODB_URI} npm test
