#!/bin/bash

# Installs the `node_management` scripts from the `supra-nodeops-data` GitHub repository.
# This script is intended to be run on a machine that hosts a Supra node.

if ! which wget &>/dev/null; then
    echo "Could not locate 'wget'. Please install it and run the script again." >&2
    exit 1
fi

mkdir -p .supra/node_management
wget -O .supra/node_management/utils.sh https://raw.githubusercontent.com/Entropy-Foundation/supra-nodeops-data/refs/heads/master/node_management/utils.sh
wget -O manage_supra_nodes.sh https://raw.githubusercontent.com/Entropy-Foundation/supra-nodeops-data/refs/heads/master/node_management/manage_supra_nodes.sh
wget -O migrate_to_v8.0.2.sh https://raw.githubusercontent.com/Entropy-Foundation/supra-nodeops-data/refs/heads/master/node_management/migrate_to_v8.0.2.sh
chmod +x manage_supra_nodes.sh migrate_to_v8.0.2.sh
