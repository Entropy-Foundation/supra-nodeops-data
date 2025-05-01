#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SCRIPT_NAME="manage_supra_nodes"

# This script is expected to be installed with `install_management_scripts.sh`, which
# creates the `.supra` directory and retrieves the `node_management` directory.
source "$SCRIPT_DIR/.supra/node_management/utils.sh"

set -e

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
    setup | update)
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
        # Shift out `<function>`.
        shift

        # Parse the optional args.
        while :; do
            case $1 in
            -e | --exact-timestamps)
                EXACT_TIMESTAMPS="SET"
                ;;
            -s | --snapshot-source)
                # TODO: Could add verification for this parameter to ensure that operators
                # don't accidentally sync the snapshot for the wrong environment.
                SNAPSHOT_SOURCE="$2"
                # Shift out the args parameter.
                shift || break
                ;;
            *)
                break
                ;;
            esac

            # Move to the next arg.
            shift || break
        done

        # Parse the remaining expected args.
        NODE_TYPE="$1"
        HOST_SUPRA_HOME="$2"
        NETWORK="$3"
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
    validator_ip_usage
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
    echo "Parameters:" >&2
    node_type_usage
    container_name_usage
    host_supra_home_usage
    exit 1
}

function sync_usage() {
    echo "Usage: ./$SCRIPT_NAME.sh sync <node_type> <host_supra_home> <network>" >&2
    echo "Parameters:" >&2
    node_type_usage
    host_supra_home_usage
    network_usage
    echo "Optional Parameters:" >&2
    echo "  -e, --exact-timestamps" >&2
    echo "     Sync all files in the database with last-modified timestamps that differ from the" >&2
    echo "     timestamp of the corresponding file in the remote snapshot. Set this parameter if" >&2
    echo "     you receive an error that indicates that your node's database might be corrupted." >&2
    echo "     This will be more efficient than removing and re-syncing the full snapshot. Afterwards," >&2
    echo "     run the command again without this parameter to confirm that all data has been" >&2
    echo "     downloaded. Note that the script will re-download the same files if you repeat the" >&2
    echo "     command with this parameter set, so do not do this." >&2
    echo " -s, --snapshot-source <snapshot_source_name>" >&2
    echo "     The name of the remote source to sync snapshots from."
    exit 1
}

function verify_setup_update_common_arguments() {
    is_semantic_version_id "$NEW_IMAGE_VERSION" &&
        verify_container_name &&
        verify_host_supra_home &&
        verify_network &&
        (is_validator || is_ipv4_address "$VALIDATOR_IP")
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
    docker start "$CONTAINER_NAME" &>/dev/null ||
        docker run \
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
    docker start "$CONTAINER_NAME" &>/dev/null ||
        docker run \
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

#---------------------------------------------------------- Utility ----------------------------------------------------------

# Download a file only if it is missing or its version is outdated.
# Creates a timestamped backup if the file exists and gets replaced.
# Usage:
#   backup_and_download_if_outdated <file_path> <download_url> <new_version> [<label>]
function backup_and_download_if_outdated() {
    local file_path="$1"
    local download_url="$2"
    local new_version_full="$3"
    local file_label="${4:-$file_path}"

    if [ -f "$file_path" ]; then
        local backup_path="${file_path}.bak.$(date +%s)"
        local current_version="$(grep -oP '^#\s*Version:\s*v?\K[0-9]+\.[0-9]+\.[0-9]+' "$file_path" || echo "")"
        local new_version="$(echo "$new_version_full" | grep -oP '^[0-9]+\.[0-9]+\.[0-9]+')"

        if [ -z "$current_version" ]; then
            cp "$file_path" "$backup_path"
            echo "No version found in $file_label. Downloading latest."
            wget -nc -O "$file_path" "$download_url"
            echo "Previous $file_label backed up to $backup_path"
        elif [ "$current_version" != "$new_version" ]; then
            cp "$file_path" "$backup_path"
            echo "Updating $file_label from version $current_version to $new_version"
            wget -nc -O "$file_path" "$download_url"
            echo "Previous $file_label backed up to $backup_path"
        fi
    else
        echo "$file_label not found. Downloading..."
        wget -nc -O "$file_path" "$download_url"
    fi
}

#---------------------------------------------------------- Setup ----------------------------------------------------------

function download_rpc_static_configuration_files() {
    local ca_certificate="$HOST_SUPRA_HOME/ca_certificate.pem"
    local client_supra_certificate="$HOST_SUPRA_HOME/client_supra_certificate.pem"
    local client_supra_key="$HOST_SUPRA_HOME/client_supra_key.pem"
    local supra_committees="$HOST_SUPRA_HOME/supra_committees.json"
    local config_toml="$HOST_SUPRA_HOME/config.toml"
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

    # Download config.toml if not present or version is missing/lower than NEW_IMAGE_VERSION
    backup_and_download_if_outdated "$config_toml" "https://${STATIC_SOURCE}.supra.com/configs/config.toml" "$NEW_IMAGE_VERSION" "config.toml"

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

    # Download smr_settings.toml if not present or version is missing/lower than NEW_IMAGE_VERSION
    backup_and_download_if_outdated "$smr_settings" "https://${STATIC_SOURCE}.supra.com/configs/smr_settings.toml" "$NEW_IMAGE_VERSION" "smr_settings.toml"

    if ! [ -f "$genesis_configs" ]; then
        wget -nc -O "$genesis_configs" "https://${STATIC_SOURCE}.supra.com/configs/genesis_configs.json"
    fi

    if ! [ -f "$genesis_config_arbitrary_data" ] && [[ "$NETWORK" == "mainnet" ]]; then
        wget -nc -O "$genesis_config_arbitrary_data" "https://${STATIC_SOURCE}.supra.com/configs/genesis_config_arbitrary_data.json"
    fi
}

function update_validator_in_config_toml() {
    local config_toml="$HOST_SUPRA_HOME/config.toml"

    if ! [ -f "$config_toml" ]; then
        sed -i'.bak' "s/<VALIDATOR_IP>/$VALIDATOR_IP/g" "$config_toml"
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
        download_rpc_static_configuration_files
        update_validator_in_config_toml
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
    download_rpc_static_configuration_files
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
    update_validator_in_config_toml
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

function start_rpc_node() {
    copy_rpc_root_config_files
    start_rpc_docker_container
    docker exec -itd $CONTAINER_NAME /supra/rpc_node start
}

function start_validator_node() {
    copy_validator_root_config_files
    start_validator_docker_container
    prompt_for_cli_password

    ESCAPED_PASSWORD=$(printf '%q' "$CLI_PASSWORD")

    expect <<EOF
        spawn docker exec -it $CONTAINER_NAME /supra/supra node smr run
        expect "password:" { send "$ESCAPED_PASSWORD\r" }
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

function sync_once() {
    local endpoint_url="$1"
    local remote_root="$2"

    local sync_options="--endpoint-url $endpoint_url --delete"

    if [ -n "$EXACT_TIMESTAMPS" ]; then
        sync_options+=" --exact-timestamps"
    fi

    if is_validator; then
        # Create the local directory if it doesn't exist
        mkdir -p "$HOST_SUPRA_HOME/smr_storage"

        # Remove the CURRENT index file. `aws sync` sometimes fails to update this properly.
        # This ensures that the correct version of the file will be downloaded from the snapshot.
        rm -f "$HOST_SUPRA_HOME/smr_storage/CURRENT"

        # Download store snapshots concurrently
        aws s3 sync "$remote_root/store/" "$HOST_SUPRA_HOME/smr_storage/" $sync_options
    elif is_rpc; then
        # Create the local directories if they don't exist
        mkdir -p "$HOST_SUPRA_HOME/rpc_store"
        mkdir -p "$HOST_SUPRA_HOME/rpc_archive"

        # Remove the CURRENT index files. `aws sync` sometimes fails to update this properly.
        # This ensures that the correct version of the file will be downloaded from the snapshot.
        rm -f "$HOST_SUPRA_HOME/rpc_store/CURRENT"
        rm -f "$HOST_SUPRA_HOME/rpc_archive/CURRENT"

        # Run the two download commands concurrently in the background
        aws s3 sync "$remote_root/store/" "$HOST_SUPRA_HOME/rpc_store/" $sync_options &
        aws s3 sync "$remote_root/archive/" "$HOST_SUPRA_HOME/rpc_archive/" $sync_options &
        wait
    fi
}

function sync() {
    # Install AWS CLI if not installed
    install_aws_cli

    # Ensure AWS CLI configuration is set up properly
    mkdir -p ~/.aws
    if [ ! -f ~/.aws/config ]; then
        cat <<EOF >~/.aws/config
[default]
region = auto
output = json
s3 =
    max_concurrent_requests = 1000
    multipart_threshold = 512MB
    multipart_chunksize = 256MB
EOF
    fi

    local bucket_name="mainnet"
    # Define the custom endpoint for Cloudflare R2
    local endpoint_url="https://4ecc77f16aaa2e53317a19267e3034a4.r2.cloudflarestorage.com"

    # Set AWS CLI credentials and bucket name based on the selected network
    if [ "$NETWORK" == "mainnet" ]; then
        export AWS_ACCESS_KEY_ID="c64bed98a85ccd3197169bf7363ce94f"
        export AWS_SECRET_ACCESS_KEY="0b7f15dbeef4ebe871ee8ce483e3fc8bab97be0da6a362b2c4d80f020cae9df7"
    elif [ "$NETWORK" == "testnet" ]; then
        export AWS_ACCESS_KEY_ID="229502d7eedd0007640348c057869c90"
        export AWS_SECRET_ACCESS_KEY="799d15f4fd23c57cd0f182f2ab85a19d885887d745e2391975bb27853e2db949"

        if is_validator; then
            bucket_name="testnet-validator-snapshot"
        elif is_rpc; then
            bucket_name="testnet-snapshot"
        fi
    fi

    if [ -n "$SNAPSHOT_SOURCE" ]; then
        # The user overrode the default snapshot source via the optional parameter.
        bucket_name="$SNAPSHOT_SOURCE"
    fi

    local remote_root="s3://${bucket_name}/snapshots"
    # The file that will be present in the `snapshots` directory of the bucket if the
    # snapshot uploader is currently uploading an update.
    local lock_file="$remote_root/UPLOAD_IN_PROGRESS"

    # Sync the current state of the bucket.
    sync_once "$endpoint_url" "$remote_root"

    # Check if an upload is in progress. If it is, then the sync that we just completed
    # will have terminated in an inconsistent state. Wait for the upload to finish, then
    # sync one more time.
    if aws s3 ls "$lock_file" --endpoint-url "$endpoint_url"; then
        echo "A new snapshot is currently being uploaded to the bucket. "
        echo -n "Waiting for the upload to complete. This may take 10-15 minutes..."

        # Wait for the upload to complete.
        while aws s3 ls "$lock_file" --endpoint-url "$endpoint_url"
        do
            sleep 10
        done

        # Sync the updated state, this time without the `--exact-timestamps` if it was set,
        # since we only want to sync the new diff. This might fail in certain edge cases,
        # in which case the operator should manually run the command again with the `--exact-timestamps`
        # flag present, but should be more efficient most of the time.
        echo "Downloading the new diff..."
        unset "$EXACT_TIMESTAMPS"
        sync_once "$endpoint_url" "$remote_root"
    fi
}

#---------------------------------------------------------- Main ----------------------------------------------------------

function main() {
    parse_args "$@"
    verify_args

    DOCKER_IMAGE="asia-docker.pkg.dev/supra-devnet-misc/supra-${NETWORK}/${NODE_TYPE}-node:${NEW_IMAGE_VERSION}"

    if [[ "$NETWORK" == "mainnet" ]]; then
        STATIC_SOURCE="mainnet-data"
    else
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
