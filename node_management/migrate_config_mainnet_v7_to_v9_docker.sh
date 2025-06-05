#!/bin/bash


set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SCRIPT_NAME="migrate_from_v7_to_v9"

# This script is expected to be installed with `install_management_scripts.sh`, which
# creates the `.supra` directory and retrieves the `node_management` directory.
source "$SCRIPT_DIR/.supra/node_management/utils.sh"

function parse_args() {
    NODE_TYPE="$1"
    CONTAINER_NAME="$2"
    HOST_SUPRA_HOME="$3"
}

function basic_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh <node_type> <container_name> <host_supra_home>" >&2
    echo "Parameters:" >&2
    node_type_usage
    container_name_usage
    host_supra_home_usage
    exit 1
}


function verify_rpc() {
    if ! verify_container_name || ! verify_host_supra_home; then
        basic_usage
    fi
}

function verify_validator() {
    if ! verify_container_name || ! verify_host_supra_home; then
        basic_usage
    fi
}

function verify_args() {
    if [[ "$NODE_TYPE" == "rpc" ]]; then
        verify_rpc
    elif [[ "$NODE_TYPE" == "validator" ]]; then
        verify_validator
    else
        basic_usage
    fi
}


#---------------------------------------------------------- RPC ----------------------------------------------------------

function migrate_rpc() {
    echo "Migrating RPC $CONTAINER_NAME at $HOST_SUPRA_HOME to v9"
    # TODO(sc): replace with mainnet image
    RPC_V9_IMAGE=asia-docker.pkg.dev/supra-devnet-misc/supra-testnet/rpc-node:v9.0.12

    rpc-v9() { docker exec -it rpc-v9 /supra/rpc_node "$@"; }

    echo "Stop the user's container if it is running."
    docker rm -f "$CONTAINER_NAME" || :

    echo "Prepare containers needed for running migration."
    # Stop+Remove rpc containers for migration if they exist.
    docker rm -f rpc-v9 || :

    docker run --name rpc-v9 \
        -v "$HOST_SUPRA_HOME:/supra/configs" \
        -e "SUPRA_HOME=/supra/configs/" \
        -itd "$RPC_V9_IMAGE"

    echo "Migrate rpc config from v7 to v9"
    # TODO(SC) to run in docker context, update path to `./configs/config.toml`
    migrate-config rpc -p v7-v9 -f $HOST_SUPRA_HOME/config.toml -t $HOST_SUPRA_HOME/config.toml


    echo "Cleanup containers used for migration."
    docker rm -f rpc-v9 || :
    docker container ls

    echo "Remove snapshot and snapshots directories"
    # Remove any existing snapshots. If we don't do this then they will start to take
    # up a large amount of disk space during the sync.
    # TODO(sc): WHY?
    rm -rf "$HOST_SUPRA_HOME/snapshot"
    rm -rf "$HOST_SUPRA_HOME/snapshots"

    # Finished migration, and follow guide that start the node  with the new image with new config and sync
    # ------

    # ./manage_supra_nodes.sh \
    #     sync \
    #     --exact-timestamps \
    #     --snapshot-source testnet-archive-snapshot \
    #     rpc \
    #     "$HOST_SUPRA_HOME" \
    #     testnet
    # echo "Migration complete. Please transfer all custom settings from $v8_config_toml to "
    # echo -n "$config_toml before starting your node."

     echo "Migration rpc config complete."

}

#---------------------------------------------------------- Validator ----------------------------------------------------------

function migrate_validator() {
    echo "Migrating validator $CONTAINER_NAME at $HOST_SUPRA_HOME to v9"

    SUPRA_V9_IMAGE=asia-docker.pkg.dev/supra-devnet-misc/supra-mainnet/validator-node:v9.0.5
    SUPRA_V8_IMAGE=asia-docker.pkg.dev/supra-devnet-misc/supra-mainnet/validator-node:v8.0.3
    supra-v8() { docker exec -it supra-v8 /supra/supra "$@"; }
    supra-v9() { docker exec -it supra-v9 /supra/supra "$@"; }


    echo "Stop the users' container if it is running."
    docker stop "$CONTAINER_NAME" || :

    echo "Prepare containers needed for running migration."
    docker rm -f supra-v8 || :
    docker rm -f supra-v9 || :

    # Start supra containers with proper env and volume mounts.
    docker run --name supra-v8 \
        -v "$HOST_SUPRA_HOME:/supra/configs" \
        -e "SUPRA_HOME=/supra/configs/" \
        -itd "$SUPRA_V8_IMAGE"

    docker run --name supra-v9 \
        -v "$HOST_SUPRA_HOME:/supra/configs" \
        -e "SUPRA_HOME=/supra/configs/" \
        -itd "$SUPRA_V9_IMAGE"


     
    echo "Migrate cli profile from v7 to v8"
    supra-v8 migrate --network mainnet
    cp $HOST_SUPRA_HOME/validator_identity.pem $HOST_SUPRA_HOME/node_identity.pem
    echo "Migrate cli profile from v8 to v9"
    supra-v9 profile migrate
    echo "Migrate smr_settings from v7 to v9"
    # TODO(SC) to be run in docker context, update path to `./configs/config.toml`
    migrate-config smr -p v7-v9 -f $HOST_SUPRA_HOME/smr_settings.toml -t $HOST_SUPRA_HOME/smr_settings.toml

    # # Localnet only (Optional: local env path is different from docker env path, need to be modified to use docker env path)
    # sed -i "" "s#${HOST_SUPRA_HOME}#configs#g" ${HOST_SUPRA_HOME}/smr_settings.toml

    echo "Cleanup containers used for migration."
    docker rm -f supra-v8 || :
    docker rm -f supra-v9 || :
    docker container ls

    echo "Remove snapshot and snapshots directories"
    # Remove any existing snapshots. If we don't do this then they will start to take
    # up a large amount of disk space during the sync.
    # TODO(sc): WHY?
    rm -rf "$HOST_SUPRA_HOME/snapshot"
    rm -rf "$HOST_SUPRA_HOME/snapshots"

    # Finished migration, and follow guide that start the node  with the new image with new config and sync

    echo "Migration validator config complete."
}

function main() {
    if [ "$#" -lt 3 ]; then
        basic_usage
    fi
    parse_args "$@"
    verify_args
    ensure_supra_home_is_absolute_path

    if [ "$NODE_TYPE" == "validator" ]; then
        migrate_validator
    elif [ "$NODE_TYPE" == "rpc" ]; then
        migrate_rpc
    fi
}

main "$@"
