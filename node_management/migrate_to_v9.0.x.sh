#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_NAME="migrate_to_v9.0.x"

# This script is expected to be installed with `install_management_scripts.sh`, which
# creates the `.supra` directory and retrieves the `node_management` directory.
source "$SCRIPT_DIR/.supra/node_management/utils.sh"

function parse_args() {
    NODE_TYPE="$1"
    CONTAINER_NAME="$2"
    HOST_SUPRA_HOME="$3"

    case "$NODE_TYPE" in
        validator)
            NETWORK="$4"
            ;;
    esac
}

function basic_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh <node_type> <[node_type_args...]>" >&2
    echo "Parameters:" >&2
    node_type_usage
    echo "  - node_type_args: The arguments required for the node type. Run './$SCRIPT_NAME.sh <node_type>' for more details." >&2
    exit 1
}

function rpc_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh rpc <container_name> <host_supra_home>" >&2
    echo "Parameters:" >&2
    container_name_usage
    exit 1
}

function validator_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh validator <container_name> <host_supra_home> <network>" >&2
    echo "Parameters:" >&2
    container_name_usage
    host_supra_home_usage
    network_usage
    exit 1
}

function verify_rpc() {
    if ! verify_container_name || ! verify_host_supra_home; then
        rpc_usage
    fi
}

function verify_validator() {
    if ! verify_container_name || ! verify_host_supra_home || ! verify_network; then
        validator_usage
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

function migrate_rpc_database() {
    docker exec -it "$CONTAINER_NAME" /supra/rpc_node migrate-db ./configs/config.toml 
}

function migrate_rpc() {
    echo "Migrating RPC $CONTAINER_NAME at $HOST_SUPRA_HOME to v9.0.x..."
    migrate_rpc_database
    echo "Migration complete."
}

#---------------------------------------------------------- Validator ----------------------------------------------------------

function migrate_validator_database() {
    echo "Migrating the Validator Database"
    docker exec -it "$CONTAINER_NAME" /supra/supra migrate -p ./configs/smr_settings.toml
    echo "Migration Complete."
}

function migrate_validator() {
    echo "Migrating validator $CONTAINER_NAME at $HOST_SUPRA_HOME to v9.0.x..."
    migrate_validator_database
    echo "Migration complete."
}

function main() {
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
