#!/bin/bash

set -e

NODE_TYPE="$1"
NEW_IMAGE_VERSION="$2"
CONTAINER_NAME="$3"
HOST_SUPRA_HOME="$4"
NETWORK="$5"

if [ "$NODE_TYPE" == "rpc" ]; then
    VALIDATOR_IP="$6"
    SYNC_SNAPSHOT="$7"
else
    SYNC_SNAPSHOT="${6:-}"
fi

if [ -z "$SYNC_SNAPSHOT" ]; then
        
    echo "SYNC_SNAPSHOT is not provided. Continuing without snapshot sync."
else
    echo "SYNC_SNAPSHOT parameter enabled: $SYNC_SNAPSHOT"
fi

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

DOCKER_IMAGE="asia-docker.pkg.dev/supra-devnet-misc/supra-${NETWORK}/${NODE_TYPE}-node:${NEW_IMAGE_VERSION}"

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


function extract_all_functions_from_file() {
    local source_file="$1"

    if [ ! -f "$source_file" ]; then
        echo "Error: Source file not found: $source_file" >&2
        return 1
    fi

    # Extract all functions from the file
    awk '/^[[:space:]]*function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*\(\)/ {print; f=1; next} f && /^}/ {print; f=0} f' "$source_file"
}

# Example usage:
source_file="manage_supra_node.sh"
extract_all_functions_from_file "$source_file" > temp_functions.sh
source temp_functions.sh
rm -f temp_functions.sh

function prompt_for_cli_password() {
    local password=""
    # while [ -z "$password" ]; do
        read -r -s -p "Enter the password for your CLI profile: " password
        echo ""  # Adds a newline after the password prompt
    # done
    echo "$password"
}

function migrate_validator_profile(){
    echo "Migrating current profile....."    
    CLI_PASSWORD=$(prompt_for_cli_password)
    expect << EOF
        spawn docker exec -it "$CONTAINER_NAME" /supra/supra migrate --network $NETWORK 
        expect "Enter your password:" { send "$CLI_PASSWORD\r" }
	    expect "Enter your password:" { send "$CLI_PASSWORD\r" }
        expect eof
EOF
}

function migrate_rpc_profile(){
    echo "Migrating current profile....."    
    docker exec -it $CONTAINER_NAME /supra/rpc_node migrate-db ./configs/config.toml 
}

function rename_validator_identity(){
    echo "renaming validator_identity to node_identity"
    cp $HOST_SUPRA_HOME/validator_identity.pem $HOST_SUPRA_HOME/node_identity.pem
}


function update_validator_existing_container() {
    echo "Updating $CONTAINER_NAME..."
    ensure_supra_home_is_absolute_path
    maybe_update_container
    download_validator_static_configuration_files
    start_validator_docker_container
    migrate_validator_profile
    rename_validator_identity
    if [ "$SYNC_SNAPSHOT" == "sync_snapshot" ]; then
        sync_validator_snapshots
    fi
    echo "Container update completed."
}

function update_rpc_existing_container() {
    echo "Updating $CONTAINER_NAME..."
    ensure_supra_home_is_absolute_path
    maybe_update_container
    download_rpc_static_configuration_files
    start_rpc_docker_container
    update_config_toml
    migrate_rpc_profile
    if [ "$SYNC_SNAPSHOT" == "sync_snapshot" ]; then
        sync_rpc_snapshots
    fi
    echo "Container update completed."
}

# Main execution logic
if [ "$NODE_TYPE" == "validator" ]; then
    update_validator_existing_container
elif [ "$NODE_TYPE" == "rpc" ]; then
    update_rpc_existing_container
fi
