#!/bin/bash

set -e

function node_type_usage() {
    echo "  - node_type: Choose the appropriate node type. Either 'validator' or 'rpc'" >&2
}

function container_name_usage() {
    echo "  - container_name: The name of your Supra Docker container." >&2
}

function host_supra_home_usage() {
    echo "  - host_supra_home: The directory on the local host to be mounted as \$SUPRA_HOME in the Docker container." >&2
}

function image_version_usage() {
    echo "  - image_version: The RPC node Docker image version to use. Must be a valid semantic versioning identifier: i.e. 'v<major>.<minor>.<patch>'." >&2
}

function network_usage() {
    echo "  - network: The network to sync with. Either 'testnet' or 'mainnet'." >&2
}

function validator_ip_usage() {
    echo "  - validator_ip: The IP address of the validator to sync consensus data from. Must be a valid IPv4 address: i.e. '[0-9]+.[0-9]+.[0-9]+.[0-9]+'" >&2
}

function is_ipv4_address() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

function is_semantic_version_id() {
    local id="$1"
    [[ "$id" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

function is_rpc() {
    [[ "$NODE_TYPE" == "rpc" ]]
}

function is_validator() {
    [[ "$NODE_TYPE" == "validator" ]]
}

function verify_container_name() {
    [ -n "$CONTAINER_NAME" ]
}

function verify_host_supra_home() {
    [ -n "$HOST_SUPRA_HOME" ]
}

function verify_network() {
    [ "$NETWORK" == "mainnet" ] || [ "$NETWORK" == "testnet" ]
}

function verify_node_type() {
    [ -n "$NODE_TYPE" ]
}

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
    # Enter it and get the fully-qualified path in case it was given as a relative path.
    cd "$HOST_SUPRA_HOME"
    HOST_SUPRA_HOME="$(pwd)"
}

function prompt_for_cli_password() {
    while [ -z "$CLI_PASSWORD" ]; do
        read -r -s -p "Enter the password for your CLI profile: " CLI_PASSWORD
    done
}

# Helper function to install AWS CLI v2 if not already installed
function install_aws_cli() {
    export AWS_MAX_CONCURRENT_REQUESTS=350  # Adjust based on system resources
    export AWS_MAX_QUEUE_SIZE=10000  # Increase queue size for large downloads

    if ! which aws >/dev/null; then
        echo "AWS CLI not found, installing..."
        if ! which unzip >/dev/null; then
            echo "unzip not found. Installing unzip..."
            sudo apt-get update && sudo apt-get install -y unzip
        fi
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip >/dev/null
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi
}
