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

    if [ -f "$config_toml" ]; then
        sed -i'.bak' "s/<VALIDATOR_IP>/$VALIDATOR_IP/g" "$config_toml"
        echo "✅ Updated validator IP to $VALIDATOR_IP in config.toml"
    else
        echo "⚠️ config.toml not found at $config_toml, cannot update VALIDATOR_IP"
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
# Ensure rclone is installed
function install_rclone_if_missing() {
    local assume_yes="$1"  # pass "--assume=yes" to skip prompt

    if ! command -v rclone &> /dev/null; then
        echo "⚠️  'rclone' is not installed."

        if [[ "$assume_yes" == "--assume=yes" ]]; then
            echo "🔧 Automatically installing rclone (assume=yes)..."
            curl -L https://rclone.org/install.sh | sudo bash
            echo "✅ rclone installed."
            return
        fi

        # Prompt the user
        read -p "Do you want to install rclone automatically from https://rclone.org/install.sh? [y/N] " confirm
        confirm=${confirm,,}  # convert to lowercase

        if [[ "$confirm" == "y" || "$confirm" == "yes" ]]; then
            echo "🔧 Installing rclone..."
            curl -L https://rclone.org/install.sh | sudo bash
            echo "✅ rclone installed."
        else
            echo "❌ rclone installation skipped by user."
            echo ""
            echo "📌 To install rclone manually, run the following:"
            echo "  curl -L https://rclone.org/install.sh | sudo bash"
            echo ""
            exit 1
        fi
    else
        echo "✅ rclone is already installed."
    fi
}
#---------------------------------------------------------- Setup Rclone Config ----------------------------------------------------------
function setup_rclone_config_if_missing() {
    local config_path="$HOME/.config/rclone"
    local config_file="rclone.conf"
    local full_config_path="$config_path/$config_file"
    
    mkdir -p "$config_path"

    # Ensure the file exists before appending
    touch "$full_config_path"

    if [[ "$NETWORK" == "mainnet" ]]; then
        export RCLONE_REMOTE_NAME="cloudflare-r2-mainnet"
        export RCLONE_ACCESS_KEY_ID="ba3e917e8f1eb35772059f8eb3736cac"
        export RCLONE_SECRET_ACCESS_KEY="432bbb569498de327299a40b6b2357dc282ff4158e939efbe6c75807c4885e3b"
        export RCLONE_ACCOUNT_ID="4ecc77f16aaa2e53317a19267e3034a4"
    elif [[ "$NETWORK" == "testnet" ]]; then
        export RCLONE_REMOTE_NAME="cloudflare-r2-testnet"
        export RCLONE_ACCESS_KEY_ID="20f826bb30ea7205116e2adc7f19e34d"
        export RCLONE_SECRET_ACCESS_KEY="1ad51161a013f1115381197929524cc1ff91fbccf016717652af8adf8fa2ed98"
        export RCLONE_ACCOUNT_ID="4ecc77f16aaa2e53317a19267e3034a4"
    else
        echo "❌ Unsupported network: $NETWORK"
        exit 1
    fi

    if ! grep -q "^\[$RCLONE_REMOTE_NAME\]" "$config_path/$config_file" 2>/dev/null; then
        echo "Configuring rclone remote: $RCLONE_REMOTE_NAME"
        cat <<EOF >> "$config_path/$config_file"
[$RCLONE_REMOTE_NAME]
type = s3
provider = Cloudflare
access_key_id = ${RCLONE_ACCESS_KEY_ID}
secret_access_key = ${RCLONE_SECRET_ACCESS_KEY}
endpoint = https://${RCLONE_ACCOUNT_ID}.r2.cloudflarestorage.com
region = auto
chunk_size = 512M
upload_cutoff = 512M
EOF
    else
        echo "✅ Rclone remote $RCLONE_REMOTE_NAME already exists."
    fi
}
#---------------------------------------------------------- Sync Snapshot Directory ----------------------------------------------------------
function sync_snapshot_dir() {
    local remote_subpath="$1"    # e.g. "cloudflare-r2-testnet:testnet-snapshot/snapshots/store"
    local destination_path="$2"  # e.g. "$HOST_SUPRA_HOME/rpc_store"
    local log_suffix="$3"        # e.g. "store", "archive", "smr"

    # Sync options
    local sync_options=(
        --multi-thread-streams 16
        --transfers 32
        --checkers 128
        --fast-list
        --low-level-retries 20
        --retries 10
        --progress
        --log-level INFO
        --log-file "./rclone-sync-${log_suffix}.log"
    )

    mkdir -p "$destination_path"
    rm -f "$destination_path/CURRENT"

    echo "⬇️  Downloading snapshot from $remote_subpath to $destination_path ..."
    
    # Conditionally add --dry-run if set
    if [[ -n "$DRY_RUN" ]]; then
        rclone sync "$remote_subpath" "$destination_path" --dry-run "${sync_options[@]}"
    else
        rclone sync "$remote_subpath" "$destination_path" "${sync_options[@]}"
    fi
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
    if is_rpc; then
        update_validator_in_config_toml
    fi
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
    local remote_root="$1"
    if is_validator; then
        mkdir -p "$HOST_SUPRA_HOME/smr_storage"
        rm -f "$HOST_SUPRA_HOME/smr_storage/CURRENT"
        sync_snapshot_dir "$remote_root/store" "$HOST_SUPRA_HOME/smr_storage" "smr"
    elif is_rpc; then
        mkdir -p "$HOST_SUPRA_HOME/rpc_store"
        mkdir -p "$HOST_SUPRA_HOME/rpc_archive"
        rm -f "$HOST_SUPRA_HOME/rpc_store/CURRENT"
        rm -f "$HOST_SUPRA_HOME/rpc_archive/CURRENT"
        sync_snapshot_dir "$remote_root/store" "$HOST_SUPRA_HOME/rpc_store" "store" &
        sync_snapshot_dir "$remote_root/archive" "$HOST_SUPRA_HOME/rpc_archive" "archive" &
        wait
    fi
}

function sync() {
    install_rclone_if_missing
    setup_rclone_config_if_missing

    if [[ "$1" == "--dry-run" ]]; then
        echo "Running in dry-run mode..."
        DRY_RUN="--dry-run"
    else
        DRY_RUN=""
    fi

    # Determine bucket name
    if [ -n "$SNAPSHOT_SOURCE" ]; then
        bucket_name="$SNAPSHOT_SOURCE"
    elif [ "$NETWORK" == "mainnet" ]; then
        bucket_name=$(is_validator && echo "mainnet-validator-snapshot" || echo "mainnet")
    elif [ "$NETWORK" == "testnet" ]; then
        bucket_name=$(is_validator && echo "testnet-validator-snapshot" || echo "testnet-snapshot")
    fi

    local remote_root="${RCLONE_REMOTE_NAME}:${bucket_name}/snapshots"
    lock_dir="${remote_root}/"
    lock_filename="UPLOAD_IN_PROGRESS"
    sync_once "$remote_root"
    echo "🔍 Checking for lock file: ${lock_dir}${lock_filename}"
    if rclone lsf "$lock_dir" | grep -q "^${lock_filename}$"; then
        echo "🚧 A new snapshot is currently being uploaded to the bucket."
        echo -n "⏳ Waiting for the upload to complete. This may take 10–15 minutes..."

        local retries=60
        local count=0
        while rclone lsf "$lock_dir" | grep -q "^${lock_filename}$"; do
            echo -n "."
            sleep 10
            ((count++))
            if [[ $count -ge $retries ]]; then
                echo ""
                echo "❌ Timeout: Upload lock file still exists after 10 minutes."
                exit 1
            fi
        done

        echo ""
        echo "✅ Upload completed. Proceeding to sync..."
        echo "📥 Downloading snapshot from $remote_root ..."
        sync_once "$remote_root"
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