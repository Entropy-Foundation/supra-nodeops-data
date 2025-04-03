#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_NAME="manage_supra_nodes"

# This script is expected to be installed with `install_management_scripts.sh`, which
# creates the `.supra` directory and retrieves the `node_management` directory.
source "$SCRIPT_DIR/.supra/node_management/utils.sh"

set -e

MAINNET_RCLONE_CONFIG_NAME="cloudflare-r2-mainnet"
MAINNET_RCLONE_CONFIG="[$MAINNET_RCLONE_CONFIG_NAME]
type = s3
provider = Cloudflare
access_key_id = c64bed98a85ccd3197169bf7363ce94f
secret_access_key = 0b7f15dbeef4ebe871ee8ce483e3fc8bab97be0da6a362b2c4d80f020cae9df7
region = auto
endpoint = https://4ecc77f16aaa2e53317a19267e3034a4.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
"

# TODO: Move this to separate location and version it. The script should pull the input version.
MAINNET_RPC_CONFIG_TOML='####################################### PROTOCOL PARAMETERS #######################################

# The below parameters are fixed for the protocol and must be agreed upon by all node operators
# at genesis. They may subsequently be updated via governance decisions.

# Core protocol parameters.

# A unique identifier for this instance of the Supra protocol. Prevents replay attacks across chains.
chain_instance.chain_id = 8
# The length of an epoch in seconds.
chain_instance.epoch_duration_secs = 7200
# The number of seconds that stake locked in a Stake Pool will automatically be locked up for when
# its current lockup expires, if no request is made to unlock it.
#
# 48 hours.
chain_instance.recurring_lockup_duration_secs = 172800
# The number of seconds allocated for voting on governance proposals. Governance will initially be 
# controlled by The Supra Foundation.
#
# 46 hours.
chain_instance.voting_duration_secs = 165600
# Determines whether the network will start with a faucet, amongst other things.
chain_instance.is_testnet = false
# Wednesday, Nov 20, 2024 12:00:00.000 AM (UTC).
chain_instance.genesis_timestamp_microseconds = 1732060800000000


######################################### NODE PARAMETERS #########################################

# The below parameters are node-specific and may be configured as required by the operator.

# The port on which the node should listen for incoming RPC requests.
bind_addr = "0.0.0.0:30000"
# If `true` then blocks will not be verified before execution. This value should be `false`
# unless you also control the node from which this RPC node is receiving blocks.
block_provider_is_trusted = false
# The path to the TLS certificate for the connection with the attached validator.
consensus_client_cert_path = "./configs/client_supra_certificate.pem"
# The path to the private key to be used when negotiating TLS connections.
consensus_client_private_key_path = "./configs/client_supra_key.pem"
# The path to the TLS root certificate authority certificate.
consensus_root_ca_cert_path = "./configs/ca_certificate.pem"
# The websocket address of the attached validator.
consensus_rpc = "ws://<VALIDATOR_IP>:26000"
# If true, all components will attempt to load their previous state from disk. Otherwise,
# all components will start in their default state. Should always be `true` for testnet and
# mainnet.
resume = true
# The path to `supra_committees.json`.
supra_committees_config = "./configs/supra_committees.json"
# The number of seconds to wait before retrying a block sync request.
sync_retry_interval_in_secs = 1

# Parameters for the RPC Archive database. This database stores the indexes used to serve RPC API calls.
[database_setup.dbs.archive.rocks_db]
# The path at which the database should be created.
path = "./configs/rpc_archive"
# Whether snapshots should be taken of the database.
enable_snapshots = true

# Parameters for the DKG database.
[database_setup.dbs.ledger.rocks_db]
# The path at which the database should be created.
path = "./configs/rpc_ledger"

# Parameters for the blockchain database.
[database_setup.dbs.chain_store.rocks_db]
# The path at which the database should be created.
path = "./configs/rpc_store"
# Whether snapshots should be taken of the database.
enable_snapshots = true

# Parameters for the database snapshot service.
[database_setup.snapshot_config]
# The number of snapshots to retain, including the latest.
depth = 2
# The interval between snapshots in seconds.
interval_in_seconds = 1800
# The path at which the snapshots should be stored.
path = "./configs/snapshot"
# The number of times to retry a snapshot in the event that it fails unexpectedly.
retry_count = 3
# The interval in seconds to wait before retring a snapshot.
retry_interval_in_seconds = 5

# CORS settings for RPC API requests.
[[allowed_origin]]
url = "https://rpc-mainnet.supra.com"
description = "RPC For Supra"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-mainnet1.supra.com"
description = "RPC For nodeops group1"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-mainnet2.supra.com"
description = "RPC For nodeops group2"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-mainnet3.supra.com"
description = "RPC For nodeops group3"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-mainnet4.supra.com"
description = "RPC For nodeops group4"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-mainnet5.supra.com"
description = "RPC For nodeops group5"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-wallet-mainnet.supra.com"
description = "RPC For Supra Wallet"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-suprascan-mainnet.supra.com"
description = "RPC For suprascan"
mode = "Server"

[[allowed_origin]]
url = "http://localhost:27000"
description = "LocalNet"
mode = "Server"
'

TESTNET_RCLONE_CONFIG_NAME="cloudflare-r2-testnet"
TESTNET_RCLONE_CONFIG="[$TESTNET_RCLONE_CONFIG_NAME]
type = s3
provider = Cloudflare
access_key_id = 229502d7eedd0007640348c057869c90
secret_access_key = 799d15f4fd23c57cd0f182f2ab85a19d885887d745e2391975bb27853e2db949
region = auto
endpoint = https://4ecc77f16aaa2e53317a19267e3034a4.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
"

# TODO: Move this to separate location and version it. The script should pull the input version.
TESTNET_RPC_CONFIG_TOML='####################################### PROTOCOL PARAMETERS #######################################

# The below parameters are fixed for the protocol and must be agreed upon by all node operators
# at genesis. They may subsequently be updated via governance decisions.

# Core protocol parameters.
# The below parameters are node-specific and may be configured as required by the operator.

# The port on which the node should listen for incoming RPC requests.
bind_addr = "0.0.0.0:26000"
# If `true` then blocks will not be verified before execution. This value should be `false`
# unless you also control the node from which this RPC node is receiving blocks.
block_provider_is_trusted = true
resume = true
# The path to `supra_committees.json`.
supra_committees_config = "./configs/supra_committees.json"
consensus_access_tokens = []

# A unique identifier for this instance of the Supra protocol. Prevents replay attacks across chains.
[chain_instance]
chain_id = 6
# The length of an epoch in seconds.
epoch_duration_secs = 7200
# The number of seconds that stake locked in a Stake Pool will automatically be locked up for when
# its current lockup expires, if no request is made to unlock it.
recurring_lockup_duration_secs = 14400
# The number of seconds allocated for voting on governance proposals. Governance will initially be controlled by The Supra Foundation.
voting_duration_secs = 7200
# Determines whether the network will start with a faucet, amongst other things.
is_testnet = true
# Tuesday, September 17, 2024 12:00:00.000 PM (UTC)
genesis_timestamp_microseconds = 1726574400000000


######################################### NODE PARAMETERS #########################################
[chain_state_assembler]
certified_block_cache_bucket_size = 50
sync_retry_interval_in_secs = 1

[synchronization.ws]
# The path to the TLS certificate for the connection with the attached validator.
consensus_client_cert_path = "./configs/client_supra_certificate.pem"
# The path to the private key to be used when negotiating TLS connections.
consensus_client_private_key_path = "./configs/client_supra_key.pem"
# The path to the TLS root certificate authority certificate.
consensus_root_ca_cert_path = "./configs/ca_certificate.pem"
# The websocket address of the attached validator.
consensus_rpc = "ws://<VALIDATOR_IP>:26000"

# Parameters for the RPC Archive database. This database stores the indexes used to serve RPC API calls.
[database_setup.dbs.archive.rocks_db]
# The path at which the database should be created.
path = "./configs/rpc_archive"
# Whether snapshots should be taken of the database.
enable_snapshots = true

# Parameters for the DKG database.
[database_setup.dbs.ledger.rocks_db]
# The path at which the database should be created.
path = "./configs/rpc_ledger"

# Parameters for the blockchain database.
[database_setup.dbs.chain_store.rocks_db]
# The path at which the database should be created.
path = "./configs/rpc_store"
# Whether snapshots should be taken of the database.
enable_snapshots = true

# Parameters for the database snapshot service.
[database_setup.snapshot_config]
# The number of snapshots to retain, including the latest.
depth = 2
# The interval between snapshots in seconds.
interval_in_seconds = 1800
# The path at which the snapshots should be stored.
path = "./configs/snapshot"
# The number of times to retry a snapshot in the event that it fails unexpectedly.
retry_count = 3
# The interval in seconds to wait before retrying a snapshot.
retry_interval_in_seconds = 5

# CORS settings for RPC API requests. The below settings are the default values required for use in RPC nodes run by validator node operators. They are optional for non-validators.
[[allowed_origin]]
url = "https://rpc-testnet.supra.com"
description = "RPC For Supra Scan and Faucet"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-testnet1.supra.com"
description = "RPC For nodeops group1"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-testnet2.supra.com"
description = "RPC For nodeops group2"
mode = "Server"

[[allowed_origin]]

url = "https://rpc-testnet3.supra.com"
description = "RPC For nodeops group3"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-testnet4.supra.com"
description = "RPC For nodeops group4"
mode = "Server"

[[allowed_origin]]
url = "https://rpc-testnet5.supra.com"
description = "RPC For nodeops group5"
mode = "Server"

[[allowed_origin]]
url = "http://localhost:27000"
description = "LocalNet"
mode = "Server"
'

function is_setup() {
    [[ "$FUNCTION" == "setup" ]]
}

function is_start() {
    [[ "$FUNCTION" = "start" ]]
}

function is_sync() {
    [[ "$FUNCTION" = "sync" ]]
}

function is_update() {
    [[ "$FUNCTION" = "update" ]]
}

function parse_args() {
    FUNCTION="$1"
    NODE_TYPE="$2"

    case "$FUNCTION" in
        setup|update)
            NEW_IMAGE_VERSION="$3"
            CONTAINER_NAME="$4"
            HOST_SUPRA_HOME="$5"
            NETWORK="$6"
            ;;
        start)
            CONTAINER_NAME="$3"
            HOST_SUPRA_HOME="$4"
            ;;
        sync)
            HOST_SUPRA_HOME="$3"
            NETWORK="$4"
            ;;
    esac

    if (is_setup || is_update) && is_rpc; then
        VALIDATOR_IP="$7"
    fi
}

function basic_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh <function> <node_type> <[function_args...]>" >&2
    echo "Parameters:" >&2
    echo "  - function: The function to execute: 'setup' or 'update' or 'start' or 'sync'." >&2
    node_type_usage
    echo "  - function_args: The arguments required by the function. Run './$SCRIPT_NAME.sh <function>' for more details." >&2
    exit 1
}

function function_node_type_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh $FUNCTION <node_type> <[node_type_args...]>" >&2
    echo "Parameters:" >&2
    node_type_usage
    echo "  - node_type_args: The $FUNCTION arguments required by the given node type. Run './$SCRIPT_NAME.sh $FUNCTION <node_type>' for more details." >&2
}

function validator_common_parameters() {
    echo "Parameters:" >&2
    image_version_usage
    container_name_usage
    host_supra_home_usage
    network_usage
}

function rpc_common_parameters() {
    echo "Parameters:" >&2
    image_version_usage
    container_name_usage
    host_supra_home_usage
    network_usage
    echo "  - validator_ip: The IP address of the validator to sync consensus data from. Must be a valid IPv4 address: i.e. '[0-9]+.[0-9]+.[0-9]+.[0-9]+'" >&2
}

function setup_usage() {
    if is_validator; then
        echo "Usage: ./$SCRIPT_NAME.sh setup $NODE_TYPE <image_version> <container_name> <host_supra_home> <network>" >&2
        validator_common_parameters
    elif is_rpc; then
        echo "Usage: ./$SCRIPT_NAME.sh setup $NODE_TYPE <image_version> <container_name> <host_supra_home> <network> <validator_ip>" >&2
        rpc_common_parameters
    else
        function_node_type_usage
    fi

    exit 1
}

function update_usage() {
    if is_validator; then
        echo "Usage: ./$SCRIPT_NAME.sh update $NODE_TYPE <image_version> <container_name> <host_supra_home> <network>" >&2
        validator_common_parameters
    elif is_rpc; then
        echo "Usage: ./$SCRIPT_NAME.sh update $NODE_TYPE <image_version> <container_name> <host_supra_home> <network> <validator_ip>" >&2
        rpc_common_parameters
    else
        function_node_type_usage
    fi

    exit 1
}

function start_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh start <node_type> <container_name> <host_supra_home>" >&2
    node_type_usage
    container_name_usage
    host_supra_home_usage
    exit 1
}

function sync_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh sync <node_type> <host_supra_home> <network>" >&2
    node_type_usage
    host_supra_home_usage
    network_usage
    exit 1
}

function verify_setup_update_common_arguments() {
    is_semantic_version_id "$NEW_IMAGE_VERSION" \
    && verify_container_name \
    && verify_host_supra_home \
    && verify_network \
    && (is_validator || is_ipv4_address "$VALIDATOR_IP")
}

function verify_setup() {
    if ! verify_setup_update_common_arguments; then
        setup_usage
    fi
}

function verify_update() {
    if ! verify_setup_update_common_arguments; then
        update_usage
    fi
}

function verify_start() {
    if ! verify_node_type || ! verify_container_name || ! verify_host_supra_home; then
        start_usage
    fi
}

function verify_sync() {
    if ! verify_node_type || ! verify_host_supra_home || ! verify_network; then
        sync_usage
    fi
}

function verify_args() {
    if is_setup; then
        verify_setup
    elif is_update; then
        verify_update
    elif is_start; then
        verify_start
    elif is_sync; then
        verify_sync
    else
        basic_usage
    fi
}

function start_validator_docker_container() {
    local user_id="$(id -u)"
    local group_id="$(id -g)"
    docker start "$CONTAINER_NAME" &>/dev/null \
        || docker run \
            --name "$CONTAINER_NAME" \
            --user "${user_id}:${group_id}" \
            -v "$HOST_SUPRA_HOME:/supra/configs" \
            -e "RUST_LOG=debug,sop2p=info,multistream_select=off,libp2p_swarm=off,yamux=off" \
            -e "SUPRA_HOME=/supra/configs/" \
            -e "SUPRA_LOG_DIR=/supra/configs/supra_node_logs" \
            -e "SUPRA_MAX_LOG_FILE_SIZE=500000000" \
            -e "SUPRA_MAX_UNCOMPRESSED_LOGS=20" \
            -e "SUPRA_MAX_LOG_FILES=40" \
            --net=host \
            -itd "asia-docker.pkg.dev/supra-devnet-misc/supra-${NETWORK}/validator-node:${NEW_IMAGE_VERSION}"
}

function start_rpc_docker_container() {
    local user_id="$(id -u)"
    local group_id="$(id -g)"
    docker start "$CONTAINER_NAME" &>/dev/null \
        || docker run \
            --name "$CONTAINER_NAME" \
            --user "${user_id}:${group_id}" \
            -v "$HOST_SUPRA_HOME:/supra/configs" \
            -e "RUST_LOG=debug,sop2p=info,multistream_select=off,libp2p_swarm=off,yamux=off" \
            -e "SUPRA_HOME=/supra/configs/" \
            -e "SUPRA_LOG_DIR=/supra/configs/rpc_node_logs" \
            -e "SUPRA_MAX_LOG_FILE_SIZE=500000000" \
            -e "SUPRA_MAX_UNCOMPRESSED_LOGS=20" \
            -e "SUPRA_MAX_LOG_FILES=40" \
            --net=host \
            -itd "asia-docker.pkg.dev/supra-devnet-misc/supra-${NETWORK}/rpc-node:${NEW_IMAGE_VERSION}"
}

#---------------------------------------------------------- Setup ----------------------------------------------------------

function download_rpc_static_configuration_files() {
    local ca_certificate="$HOST_SUPRA_HOME/ca_certificate.pem"
    local client_supra_certificate="$HOST_SUPRA_HOME/client_supra_certificate.pem"
    local client_supra_key="$HOST_SUPRA_HOME/client_supra_key.pem"
    local supra_committees="$HOST_SUPRA_HOME/supra_committees.json"
    local genesis_blob="$HOST_SUPRA_HOME/genesis.blob"

    # Download the TLS certificates and keys.
    if ! [ -f "$ca_certificate" ]; then
        wget -nc -O "$ca_certificate" "https://${STATIC_SOURCE}.supra.com/certificates/ca_certificate.pem"
    fi

    if ! [ -f "$client_supra_certificate" ]; then
        wget -nc -O "$client_supra_certificate" "https://${STATIC_SOURCE}.supra.com/certificates/client_supra_certificate.pem"
    fi

    if ! [ -f "$client_supra_key" ]; then
        wget -nc -O "$client_supra_key" "https://${STATIC_SOURCE}.supra.com/certificates/client_supra_key.pem"
    fi

    # And the Genesis Blob and Genesis Committee files.
    if ! [ -f "$supra_committees" ]; then
        wget -nc -O "$supra_committees" "https://${STATIC_SOURCE}.supra.com/configs/supra_committees.json"
    fi

    if ! [ -f "$genesis_blob" ]; then
        wget -nc -O "$genesis_blob" "https://${STATIC_SOURCE}.supra.com/configs/genesis.blob"
    fi
    
}

function set_ulimit() {
    local limits_file="/etc/security/limits.conf"
    local sysctl_file="/etc/sysctl.conf"

    # Define limits
    local nofile_limit="* soft nofile 1048576\n* hard nofile 1048576"
    local nproc_limit="* soft nproc 1048576\n* hard nproc 1048576"
    local sysctl_limits=(
        "fs.file-max=2097152"
        "fs.inotify.max_user_instances=1024"
        "fs.inotify.max_user_watches=1048576"
        "net.core.somaxconn=65535"
        "net.ipv4.tcp_max_syn_backlog=65535"
        "net.ipv4.ip_local_port_range=1024 65000"
        "net.ipv4.tcp_tw_reuse=1"
    )

    # Update limits.conf if missing
    if ! grep -q "^\\*.*nofile" "$limits_file"; then
        echo -e "$nofile_limit" | sudo tee -a "$limits_file"
    fi
    if ! grep -q "^\\*.*nproc" "$limits_file"; then
        echo -e "$nproc_limit" | sudo tee -a "$limits_file"
    fi

    # Update sysctl.conf if missing
    for param in "${sysctl_limits[@]}"; do
        key=$(echo "$param" | cut -d= -f1)
        if ! grep -q "^$key" "$sysctl_file"; then
            echo "$param" | sudo tee -a "$sysctl_file"
        fi
    done

    # Apply sysctl changes
    sudo sysctl --system
}


function download_validator_static_configuration_files() {
    local ca_certificate="$HOST_SUPRA_HOME/ca_certificate.pem"
    local client_supra_certificate="$HOST_SUPRA_HOME/server_supra_certificate.pem"
    local client_supra_key="$HOST_SUPRA_HOME/server_supra_key.pem"
    local supra_committees="$HOST_SUPRA_HOME/supra_committees.json"
    local genesis_blob="$HOST_SUPRA_HOME/genesis.blob"
    local smr_settings="$HOST_SUPRA_HOME/smr_settings.toml"
    local genesis_configs="$HOST_SUPRA_HOME/genesis_configs.json"
    local genesis_config_arbitrary_data="$HOST_SUPRA_HOME/genesis_config_arbitrary_data.json"

    # Download the TLS certificates and keys.
    if ! [ -f "$ca_certificate" ]; then
        wget -nc -O "$ca_certificate" "https://${STATIC_SOURCE}.supra.com/certificates/ca_certificate.pem"
    fi

    if ! [ -f "$client_supra_certificate" ]; then
        wget -nc -O "$client_supra_certificate" "https://${STATIC_SOURCE}.supra.com/certificates/server_supra_certificate.pem"
    fi

    if ! [ -f "$client_supra_key" ]; then
        wget -nc -O "$client_supra_key" "https://${STATIC_SOURCE}.supra.com/certificates/server_supra_key.pem"
    fi

    # And the Genesis Blob and Genesis Committee files.
    if ! [ -f "$supra_committees" ]; then
        wget -nc -O "$supra_committees" "https://${STATIC_SOURCE}.supra.com/configs/supra_committees.json"
    fi

    if ! [ -f "$genesis_blob" ]; then
        wget -nc -O "$genesis_blob" "https://${STATIC_SOURCE}.supra.com/configs/genesis.blob"
    fi
    
    if ! [ -f "$smr_settings" ]; then
        wget -nc -O "$smr_settings" "https://${STATIC_SOURCE}.supra.com/configs/smr_settings.toml"
    fi

    if ! [ -f "$genesis_configs" ]; then
        wget -nc -O "$genesis_configs" "https://${STATIC_SOURCE}.supra.com/configs/genesis_configs.json"
    fi

    if ! [ -f "$genesis_config_arbitrary_data" ] && [[ "$NETWORK" == "mainnet" ]]; then
        wget -nc -O "$genesis_config_arbitrary_data" "https://${STATIC_SOURCE}.supra.com/configs/genesis_config_arbitrary_data.json"
    fi
}

function setup() {
    echo "Setting up a new $NODE_TYPE node..."
    ensure_supra_home_is_absolute_path
    set_ulimit
    
    if is_validator; then
        start_validator_docker_container
        download_validator_static_configuration_files
    elif is_rpc; then
        start_rpc_docker_container
        create_config_toml
        download_rpc_static_configuration_files
    fi

    echo "$NODE_TYPE node setup completed."
}

#---------------------------------------------------------- Update ----------------------------------------------------------

function remove_old_docker_container() {
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
}

function remove_old_docker_image() {
    local old_image="$1"
    docker rmi "$old_image" &>/dev/null
}

function create_config_toml() {
    local config_toml="$HOST_SUPRA_HOME/config.toml"

    if ! [ -f "$config_toml" ]; then
        echo "$RPC_CONFIG_TOML" | sed "s/<VALIDATOR_IP>/$VALIDATOR_IP/g" > "$config_toml"
    fi
}

function update_config_toml() {
    local config_toml="$HOST_SUPRA_HOME"/config.toml
    local backup="$config_toml".old

    # Ensure that the settings file already exits. The user is expected to run `setup` before `update`.
    # If they have done this, then they must have set `HOST_SUPRA_HOME` incorrectly.
    if ! [ -f "$config_toml" ]; then
        echo "$config_toml does not exist. Please ensure that you have set <host_supra_home> correctly." >&2
        exit 3
    fi

    # Create a backup of the existing node settings file in case the operator wants to copy custom
    # settings from it.
    mv "$config_toml" "$backup"
    create_config_toml
    echo "Moved $config_toml to $backup. You will need to re-apply any custom config to the new version of the file."
}

function update_smr_settings_toml() {
    local smr_settings="$HOST_SUPRA_HOME"/smr_settings.toml
    local backup="$smr_settings".old

    # Ensure that the settings file already exits. The user is expected to run `setup` before `update`.
    # If they have done this, then they must have set `HOST_SUPRA_HOME` incorrectly.
    if ! [ -f "$smr_settings" ]; then
        echo "$smr_settings does not exist. Please ensure that you have set <host_supra_home> correctly." >&2
        exit 3
    fi

    # Create a backup of the existing node settings file in case the operator wants to copy custom
    # settings from it.
    mv "$smr_settings" "$backup"
    download_validator_static_configuration_files
    echo "Moved $smr_settings to $backup. You will need to re-apply any custom config to the new version of the file."
}

function maybe_update_container() {
    local current_image="$(current_docker_image)"

    if [[ "$current_image" == "null" ]]; then
        echo "Could not find a Supra $NODE_TYPE container called $CONTAINER_NAME. Please use the 'setup' function to create it." >&2
        exit 2
    fi

    if [[ "$current_image" == "$DOCKER_IMAGE" ]]; then
        echo "Node is already at $NEW_IMAGE_VERSION." >&2
        return
    fi

    echo "Updating $CONTAINER_NAME..."
    # Updating to a new version. Remove the existing Docker container.
    remove_old_docker_container
    remove_old_docker_image "$current_image"

    if is_validator; then
        start_validator_docker_container
        update_smr_settings_toml
    else
        start_rpc_docker_container
        update_config_toml
    fi

    echo "Container update completed."
}

function update() {
    ensure_supra_home_is_absolute_path
    maybe_update_container
}

#---------------------------------------------------------- Start ----------------------------------------------------------

function copy_rpc_root_config_files() {
    docker cp "$HOST_SUPRA_HOME"/config.toml "$CONTAINER_NAME:/supra/"
    docker cp "$HOST_SUPRA_HOME"/genesis.blob "$CONTAINER_NAME:/supra/"
}

function copy_validator_root_config_files() {
    docker cp "$HOST_SUPRA_HOME"/smr_settings.toml "$CONTAINER_NAME:/supra/"
    docker cp "$HOST_SUPRA_HOME"/genesis.blob "$CONTAINER_NAME:/supra/"
}

function start_rpc_node(){
    copy_rpc_root_config_files
    start_rpc_docker_container
    docker exec -itd $CONTAINER_NAME /supra/rpc_node start
}

function start_validator_node() {
    copy_validator_root_config_files
    start_validator_docker_container
    prompt_for_cli_password

    expect << EOF
        spawn docker exec -it $CONTAINER_NAME /supra/supra node smr run
        expect "password:" { send "$CLI_PASSWORD\r" }
        expect eof
EOF
}

function start() {
    if is_validator; then
        start_validator_node
    elif is_rpc; then
        start_rpc_node
    fi
}

#---------------------------------------------------------- Sync ----------------------------------------------------------

function sync() {
    # Install AWS CLI if not installed
    install_aws_cli

    # Ensure AWS CLI configuration is set up properly
    mkdir -p ~/.aws
    if [ ! -f ~/.aws/config ]; then
        cat <<EOF > ~/.aws/config
[default]
region = auto
output = json
s3 =
    max_concurrent_requests = 1000
    multipart_threshold = 512MB
    multipart_chunksize = 256MB
EOF
    fi

    # Set AWS CLI credentials and bucket name based on the selected network
    if [ "$NETWORK" == "mainnet" ]; then
        export AWS_ACCESS_KEY_ID="c64bed98a85ccd3197169bf7363ce94f"
        export AWS_SECRET_ACCESS_KEY="0b7f15dbeef4ebe871ee8ce483e3fc8bab97be0da6a362b2c4d80f020cae9df7"
        BUCKET_NAME="mainnet"
    elif [ "$NETWORK" == "testnet" ]; then
        export AWS_ACCESS_KEY_ID="229502d7eedd0007640348c057869c90"
        export AWS_SECRET_ACCESS_KEY="799d15f4fd23c57cd0f182f2ab85a19d885887d745e2391975bb27853e2db949"
        BUCKET_NAME="testnet-snapshot"
    fi

    # Define the custom endpoint for Cloudflare R2
    local ENDPOINT_URL="https://4ecc77f16aaa2e53317a19267e3034a4.r2.cloudflarestorage.com"

    if is_validator; then
        # Create the local directory if it doesn't exist
        mkdir -p "$HOST_SUPRA_HOME/smr_storage"
        
        # Download store snapshots concurrently
        aws s3 sync "s3://${BUCKET_NAME}/snapshots/store/" "$HOST_SUPRA_HOME/smr_storage/" \
                --endpoint-url "$ENDPOINT_URL" \
                --size-only
    elif is_rpc; then
        # Create the local directories if they don't exist
        mkdir -p "$HOST_SUPRA_HOME/rpc_store"
        mkdir -p "$HOST_SUPRA_HOME/rpc_archive"

        # Run the two download commands concurrently in the background
        aws s3 sync "s3://${BUCKET_NAME}/snapshots/store/" "$HOST_SUPRA_HOME/rpc_store/" \
                --endpoint-url "$ENDPOINT_URL" \
                --size-only &
        aws s3 sync "s3://${BUCKET_NAME}/snapshots/archive/" "$HOST_SUPRA_HOME/rpc_archive/" \
                --endpoint-url "$ENDPOINT_URL" \
                --size-only &
        wait
    fi
}

#---------------------------------------------------------- Main ----------------------------------------------------------

function main() {
    parse_args "$@"
    verify_args

    DOCKER_IMAGE="asia-docker.pkg.dev/supra-devnet-misc/supra-${NETWORK}/${NODE_TYPE}-node:${NEW_IMAGE_VERSION}"

    if [[ "$NETWORK" == "mainnet" ]]; then
        RCLONE_CONFIG="$MAINNET_RCLONE_CONFIG"
        RCLONE_CONFIG_HEADER="$MAINNET_RCLONE_CONFIG_NAME"
        RPC_CONFIG_TOML="$MAINNET_RPC_CONFIG_TOML"
        SNAPSHOT_ROOT="mainnet"
        STATIC_SOURCE="mainnet-data"
    else
        RCLONE_CONFIG="$TESTNET_RCLONE_CONFIG"
        RCLONE_CONFIG_HEADER="$TESTNET_RCLONE_CONFIG_NAME"
        RPC_CONFIG_TOML="$TESTNET_RPC_CONFIG_TOML"
        SNAPSHOT_ROOT="testnet-snapshot"
        STATIC_SOURCE="testnet-snapshot"
    fi

    if is_setup; then
        setup
    elif is_update; then
        update
    elif is_start; then
        start
    elif is_sync; then
        sync
    fi
}

main "$@"
