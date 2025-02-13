#!/bin/bash

set -e

FUNCTION="$1"
NODE_TYPE="$2"
NEW_IMAGE_VERSION="$3"
CONTAINER_NAME="$4"
HOST_SUPRA_HOME="$5"
NETWORK="$6"

if [ "$FUNCTION" == "setup" ]; then
    if [ "$NODE_TYPE" == "rpc"]; then    
        VALIDATOR_IP="$7"
    fi
fi


function basic_usage() {
    echo "Usage: ./setup.sh <function> <node_type> <[function_args...]>" >&2
    echo "Parameters:" >&2
    echo "  - function: The function to execute. Either 'setup' or 'update'." >&2
    echo "  - node_type: Choose the appropriate node type. Either 'validator' or 'rpc'" >&2
    echo "  - function_args: The arguments required by the function. Run './setup.sh <function>' for more details." >&2
    exit 1
}

function echo_validator_common_parameters() {
    echo "Parameters:" >&2
    echo "  - image_version: The Validator node Docker image version to use. Must be a valid semantic versioning identifier: i.e. 'v<major>.<minor>.<patch>'." >&2
    echo "  - container_name: The name of your Supra Validator Docker container." >&2
    echo "  - host_supra_home: The directory on the local host to be mounted as \$SUPRA_HOME in the Docker container." >&2
    echo "  - network: The network to sync with. Either 'testnet' or 'mainnet'." >&2
}


function echo_rpc_common_parameters() {
    echo "Parameters:" >&2
    echo "  - image_version: The RPC node Docker image version to use. Must be a valid semantic versioning identifier: i.e. 'v<major>.<minor>.<patch>'." >&2
    echo "  - container_name: The name of your Supra RPC Docker container." >&2
    echo "  - host_supra_home: The directory on the local host to be mounted as \$SUPRA_HOME in the Docker container." >&2
    echo "  - network: The network to sync with. Either 'testnet' or 'mainnet'." >&2
    echo "  - validator_ip: The IP address of the validator to sync consensus data from." >&2
}

function setup_usage() {
    if [ "$NODE_TYPE" == "validator" ]; then
        echo "Usage: ./setup.sh setup $NODE_TYPE <image_version> <container_name> <host_supra_home> <network>" >&2
        echo_validator_common_parameters
    elif [ "$NODE_TYPE" == "rpc" ]; then
        echo "Usage: ./setup.sh setup $NODE_TYPE <image_version> <container_name> <host_supra_home> <network> <validator_ip>" >&2
        echo_rpc_common_parameters
    fi
    exit 1
}

function update_usage() {
    echo "Usage: ./setup.sh update $NODE_TYPE <image_version> <container_name> <host_supra_home> <network>" >&2
    if [ "$NODE_TYPE" == "validator" ]; then
        echo_validator_common_parameters
    elif [ "$NODE_TYPE" == "rpc" ]; then
        echo_rpc_common_parameters
    fi
    exit 1
}

function is_semantic_version_id() {
    local id="$1"
    [[ "$id" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

function verify_network() {
    [ "$NETWORK" == "mainnet" ] || [ "$NETWORK" == "testnet" ]
}

function verify_common_arguments() {
    is_semantic_version_id "$NEW_IMAGE_VERSION" \
    && [ -n "$CONTAINER_NAME" ] \
    && [ -n "$HOST_SUPRA_HOME" ] \
    && verify_network
}

function verify_setup() {
    if ! verify_common_arguments || ! [[ "$VALIDATOR_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        setup_usage
    fi
}

function verify_update() {
    if ! verify_common_arguments; then
        update_usage
    fi
}

function verify_args() {
    if [ "$FUNCTION" == "setup" ]; then
        verify_setup
    elif [ "$FUNCTION" == "update" ]; then
        verify_update
    else
        basic_usage
    fi
}

verify_args


MAINNET_RCLONE_CONFIG_HEADER="[cloudflare-r2-mainnet]"
MAINNET_RCLONE_CONFIG="$MAINNET_RCLONE_CONFIG_HEADER
type = s3
provider = Cloudflare
access_key_id = c64bed98a85ccd3197169bf7363ce94f
secret_access_key = 0b7f15dbeef4ebe871ee8ce483e3fc8bab97be0da6a362b2c4d80f020cae9df7
region = auto
endpoint = https://4ecc77f16aaa2e53317a19267e3034a4.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
"
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

[[allowed_origin]]
url = "https://rpc-mainnet1.supra.com"
description = "RPC For nodeops group1"

[[allowed_origin]]
url = "https://rpc-mainnet2.supra.com"
description = "RPC For nodeops group2"

[[allowed_origin]]
url = "https://rpc-mainnet3.supra.com"
description = "RPC For nodeops group3"

[[allowed_origin]]
url = "https://rpc-mainnet4.supra.com"
description = "RPC For nodeops group4"

[[allowed_origin]]
url = "https://rpc-mainnet5.supra.com"
description = "RPC For nodeops group5"

[[allowed_origin]]
url = "https://rpc-wallet-mainnet.supra.com"
description = "RPC For Supra Wallet"

[[allowed_origin]]
url = "https://rpc-suprascan-mainnet.supra.com"
description = "RPC For suprascan"

[[allowed_origin]]
url = "http://localhost:27000"
description = "LocalNet"
mode = "Server"

[[allowed_origin]]
url = "https://www.starkey.app"
description = "Starkey domain"
mode = "Cors"

[[allowed_origin]]
url = "chrome-extension://fcpbddmagekkklbcgnjclepnkddbnenp"
description = "Starkey wallet extension"
mode = "Cors"

[[allowed_origin]]
url = "chrome-extension://hcjhpkgbmechpabifbggldplacolbkoh"
description = "Starkey wallet extension"
mode = "Cors"

[[allowed_origin]]
url = "https://supra.com"
description = "Supra domain"
mode = "Cors"

[[allowed_origin]]
url = "https://qa-spa.supra.com"
description = "QA Supra domain"
mode = "Cors"

[[allowed_origin]]
url = "https://qa-api.services.supra.com"
description = "QA API Supra domain"
mode = "Cors"

[[allowed_origin]]
url = "https://prod-api.services.supra.com"
description = "Prod API Supra domain"
mode = "Cors"

[[allowed_origin]]
url = "http://localhost:3000"
description = "Localhost"
mode = "Cors"

[[allowed_origin]]
url = "http://localhost:8080"
description = "Localhost"
mode = "Cors"
'

TESTNET_RCLONE_CONFIG_HEADER="[cloudflare-r2-testnet]"
TESTNET_RCLONE_CONFIG="$TESTNET_RCLONE_CONFIG_HEADER
type = s3
provider = Cloudflare
access_key_id = 229502d7eedd0007640348c057869c90
secret_access_key = 799d15f4fd23c57cd0f182f2ab85a19d885887d745e2391975bb27853e2db949
region = auto
endpoint = https://4ecc77f16aaa2e53317a19267e3034a4.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
"
TESTNET_RPC_CONFIG_TOML='####################################### PROTOCOL PARAMETERS #######################################

# The below parameters are fixed for the protocol and must be agreed upon by all node operators
# at genesis. They may subsequently be updated via governance decisions.

# Core protocol parameters.

# A unique identifier for this instance of the Supra protocol. Prevents replay attacks across chains.
chain_instance.chain_id = 6
# The length of an epoch in seconds.
chain_instance.epoch_duration_secs = 7200
# The number of seconds that stake locked in a Stake Pool will automatically be locked up for when
# its current lockup expires, if no request is made to unlock it.
chain_instance.recurring_lockup_duration_secs = 14400
# The number of seconds allocated for voting on governance proposals. Governance will initially be controlled by The Supra Foundation.
chain_instance.voting_duration_secs = 7200
# Determines whether the network will start with a faucet, amongst other things.
chain_instance.is_testnet = true
# Tuesday, September 17, 2024 12:00:00.000 PM (UTC)
chain_instance.genesis_timestamp_microseconds = 1726574400000000


######################################### NODE PARAMETERS #########################################

# The below parameters are node-specific and may be configured as required by the operator.

# The port on which the node should listen for incoming RPC requests.
bind_addr = "0.0.0.0:26000"
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
sync_retry_interval_in_secs = 5

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

[[allowed_origin]]
url = "https://rpc-testnet1.supra.com"
description = "RPC For nodeops group1"

[[allowed_origin]]
url = "https://rpc-testnet2.supra.com"
description = "RPC For nodeops group2"

[[allowed_origin]]
url = "https://rpc-testnet3.supra.com"
description = "RPC For nodeops group3"

[[allowed_origin]]
url = "https://rpc-testnet4.supra.com"
description = "RPC For nodeops group4"

[[allowed_origin]]
url = "https://rpc-testnet5.supra.com"
description = "RPC For nodeops group5"

[[allowed_origin]]
url = "http://localhost:27000"
description = "LocalNet"
mode = "Server"

[[allowed_origin]]
url = "https://www.starkey.app"
description = "Starkey domain"
mode = "Cors"

[[allowed_origin]]
url = "chrome-extension://fcpbddmagekkklbcgnjclepnkddbnenp"
description = "Starkey wallet extension"
mode = "Cors"

[[allowed_origin]]
url = "chrome-extension://hcjhpkgbmechpabifbggldplacolbkoh"
description = "Starkey wallet extension"
mode = "Cors"
'

DOCKER_IMAGE="asia-docker.pkg.dev/supra-devnet-misc/supra-${NETWORK}/rpc-node:${NEW_IMAGE_VERSION}"

if [ "$NETWORK" = "mainnet" ]; then
    RCLONE_CONFIG="$MAINNET_RCLONE_CONFIG"
    RCLONE_CONFIG_HEADER="$MAINNET_RCLONE_CONFIG_HEADER"
    RPC_CONFIG_TOML="$MAINNET_RPC_CONFIG_TOML"
    SNAPSHOT_ROOT="mainnet"
    STATIC_SOURCE="mainnet-data"
else
    RCLONE_CONFIG="$TESTNET_RCLONE_CONFIG"
    RCLONE_CONFIG_HEADER="$TESTNET_RCLONE_CONFIG_HEADER"
    RPC_CONFIG_TOML="$TESTNET_RPC_CONFIG_TOML"
    SNAPSHOT_ROOT="testnet-snapshot"
    STATIC_SOURCE="testnet-snapshot"
fi


# Functions

function current_docker_image() {
    if ! which jq &>/dev/null; then
        echo "Could not locate 'jq'. Please install it and run the script again." >&2
        exit 2
    fi

    docker inspect "$CONTAINER_NAME" | jq -r '.[0].Config.Image' 2>/dev/null
}


function ensure_supra_home_is_absolute_path() {
    # Create the directory if it doesn't exist.
    mkdir -p "$HOST_SUPRA_HOME"
    # Enter it and print the fully-qualified path in case it was given as a relative path.
    cd "$HOST_SUPRA_HOME"
    HOST_SUPRA_HOME="$(pwd)"
}


function remove_old_docker_container() {
    # Stop the Docker container if it's running
    echo "Stopping $NODE_TYPE container"
    if ! docker stop "$CONTAINER_NAME"; then
        echo "Failed to stop $NODE_TYPE container. Exiting..."
    fi
    echo "$NODE_TYPE container Stopped"

    # Remove the Docker container
    echo "Removing $NODE_TYPE container"
    if ! docker rm "$CONTAINER_NAME"; then
        echo "Failed to remove $NODE_TYPE container. Exiting..."
    fi
    echo "$NODE_TYPE container removed"
}


function remove_old_docker_image() {
    local old_image="$1"

    echo "Removing old Docker image: $old_image"
    
    if docker rmi "$old_image" &>/dev/null; then
        echo "Old Docker image removed successfully."
    else
        echo "Failed to remove old Docker image. It may not exist."
    fi
}


function maybe_update_container() {
    local current_image="$(current_docker_image)"

    if [ -n "$current_image" ] && [[ "$current_image" != "$DOCKER_IMAGE" ]]; then
        remove_old_docker_container
        remove_old_docker_image "$current_image"
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
            -e "SUPRA_LOG_DIR=/supra/configs/rpc_logs" \
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
            -e "SUPRA_LOG_DIR=/supra/configs/rpc_logs" \
            -e "SUPRA_MAX_LOG_FILE_SIZE=500000000" \
            -e "SUPRA_MAX_UNCOMPRESSED_LOGS=20" \
            -e "SUPRA_MAX_LOG_FILES=40" \
            --net=host \
            -itd "asia-docker.pkg.dev/supra-devnet-misc/supra-${NETWORK}/rpc-node:${NEW_IMAGE_VERSION}"
}


function create_config_toml() {
    local config_toml="$HOST_SUPRA_HOME/config.toml"

    if ! [ -f "$config_toml" ]; then
        echo "$RPC_CONFIG_TOML" | sed "s/<VALIDATOR_IP>/$VALIDATOR_IP/g" > "$config_toml"
    fi
}


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

    if ! [ -f "$genesis_config_arbitrary_data" ]; then
        wget -nc -O "$genesis_config_arbitrary_data" "https://${STATIC_SOURCE}.supra.com/configs/genesis_config_arbitrary_data.json"
    fi
}

function sync_validator_snapshots() {
    docker stop "$CONTAINER_NAME"

    if ! which rclone >/dev/null; then
        curl https://rclone.org/install.sh | sudo bash
    fi

    mkdir -p ~/.config/rclone/
    if ! grep "$RCLONE_CONFIG_HEADER" ~/.config/rclone/rclone.conf >/dev/null; then
        echo "$RCLONE_CONFIG" >> ~/.config/rclone/rclone.conf
    fi

    rclone sync "cloudflare-r2-${NETWORK}:${SNAPSHOT_ROOT}/snapshots/store" "$HOST_SUPRA_HOME/smr_storage/" --progress
}

function sync_rpc_snapshots() {
    docker stop "$CONTAINER_NAME"

    if ! which rclone >/dev/null; then
        curl https://rclone.org/install.sh | sudo bash
    fi

    mkdir -p ~/.config/rclone/
    if ! grep "$RCLONE_CONFIG_HEADER" ~/.config/rclone/rclone.conf >/dev/null; then
        echo "$RCLONE_CONFIG" >> ~/.config/rclone/rclone.conf
    fi

    rclone sync "cloudflare-r2-${NETWORK}:${SNAPSHOT_ROOT}/snapshots/store" "$HOST_SUPRA_HOME/rpc_store/" --progress
    rclone sync "cloudflare-r2-${NETWORK}:${SNAPSHOT_ROOT}/snapshots/archive" "$HOST_SUPRA_HOME/rpc_archive/" --progress
}


function copy_validator_root_config_files() {
    # Copy the config files required in the root of the container, to the root.
    docker cp "$HOST_SUPRA_HOME"/smr_settings.toml "$CONTAINER_NAME:/supra/configs/"
    docker cp "$HOST_SUPRA_HOME"/genesis.blob "$CONTAINER_NAME:/supra/configs/"
}

function copy_rpc_root_config_files() {
    # Copy the config files required in the root of the container, to the root.
    docker cp "$HOST_SUPRA_HOME"/config.toml "$CONTAINER_NAME:/supra/"
    docker cp "$HOST_SUPRA_HOME"/genesis.blob "$CONTAINER_NAME:/supra/configs/"
}



function update_validator_existing_container() {
    echo "Updating $CONTAINER_NAME..."
    ensure_supra_home_is_absolute_path
    maybe_update_container
    download_validator_static_configuration_files
    start_validator_docker_container
    sync_validator_snapshots
    echo "Container update completed."
}

function update_rpc_existing_container() {
    echo "Updating $CONTAINER_NAME..."
    ensure_supra_home_is_absolute_path
    maybe_update_container
    download_rpc_static_configuration_files
    start_rpc_docker_container
    sync_rpc_snapshots
    copy_rpc_root_config_files
    echo "Container update completed."
}


function setup_new_validator_node() {
    echo "Setting up a new $NODE_TYPE node..."
    ensure_supra_home_is_absolute_path
    start_validator_docker_container
    download_validator_static_configuration_files
    sync_validator_snapshots
    echo "$NODE_TYPE node setup completed."
}


function setup_new_rpc_node() {
    echo "Setting up a new $NODE_TYPE node..."
    ensure_supra_home_is_absolute_path
    start_rpc_docker_container
    create_config_toml
    download_rpc_static_configuration_files
    sync_rpc_snapshots
    copy_rpc_root_config_files
    echo "$NODE_TYPE node setup completed."
}


# Main execution logic
if [ "$FUNCTION" == "setup" ]; then
    if [ "$NODE_TYPE" == "validator" ]; then
        setup_new_validator_node
    elif ["$NODE_TYPE" == "rpc"]; then
        setup_new_rpc_node
    fi
elif [ "$FUNCTION" == "update" ]; then
    if [ "$NODE_TYPE" == "validator" ]; then
        update_validator_existing_container
    elif ["$NODE_TYPE" == "rpc"]; then
        update_rpc_existing_container
    fi
fi
