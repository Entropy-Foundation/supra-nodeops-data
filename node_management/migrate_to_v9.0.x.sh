#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SCRIPT_NAME="migrate_to_v9.0.x"

# This script is expected to be installed with `install_management_scripts.sh`, which
# creates the `.supra` directory and retrieves the `node_management` directory.
source "$SCRIPT_DIR/.supra/node_management/utils.sh"

function parse_args() {
    NODE_TYPE="$1"
    CONTAINER_NAME="$2"
    HOST_SUPRA_HOME="$3"

    if [ "$NODE_TYPE" = "rpc" ]; then
        VALIDATOR_IP="$4"
    fi
}

function basic_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh <node_type> <[node_type_args...]>" >&2
    echo "Parameters:" >&2
    node_type_usage
    echo "  - node_type_args: The arguments required for the node type. Run './$SCRIPT_NAME.sh <node_type>' for more details." >&2
    exit 1
}

function rpc_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh rpc <container_name> <host_supra_home> <validator_ip>" >&2
    echo "Parameters:" >&2
    container_name_usage
    host_supra_home_usage
    validator_ip_usage
    exit 1
}

function validator_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh validator <container_name> <host_supra_home>" >&2
    echo "Parameters:" >&2
    container_name_usage
    host_supra_home_usage
    exit 1
}

function verify_rpc() {
    if ! verify_container_name || ! verify_host_supra_home; then
        rpc_usage
    fi
}

function verify_validator() {
    if ! verify_container_name || ! verify_host_supra_home; then
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

function migrate_rpc() {
    local v8_config_toml="$HOST_SUPRA_HOME/config_v8.0.x.toml"
    local config_toml="$HOST_SUPRA_HOME/config.toml"

    echo "Migrating RPC $CONTAINER_NAME at $HOST_SUPRA_HOME to v9.0.x..."

    if ! [ -f "$v8_config_toml" ]; then
        mv "$config_toml" "$v8_config_toml"
    fi

    wget -O "$config_toml" https://testnet-snapshot.supra.com/configs/config_v9.0.7.toml
    sed -i'.bak' "s/<VALIDATOR_IP>/$VALIDATOR_IP/g" "$config_toml"
    docker stop "$CONTAINER_NAME" || :
    ./manage_supra_nodes.sh \
        sync \
        --exact-timestamps \
        --snapshot-source testnet-archive-snapshot \
        rpc \
        "$HOST_SUPRA_HOME" \
        testnet
    echo "Migration complete. Please transfer all custom settings from $v8_config_toml to "
    echo -n "$config_toml before starting your node."
}

#---------------------------------------------------------- Validator ----------------------------------------------------------

function migrate_validator_database() {
    echo "Migrating the Validator Database"
    docker exec -it "$CONTAINER_NAME" /supra/supra data migrate --max-buffer-record-count 100000 -p ./configs/smr_settings.toml
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
