"""
Migration script for upgrading Supra smr_settings config files from version v7 to v9.

This module provides functions to transform configuration files in TOML format to be compatible with v9.
The migration includes the following changes:

1. Removal of the `[move_vm]` table from the configuration.
2. Migration of WebSocket server certificate paths:
    - Moves `root_ca_cert_path`, `server_cert_path`, and `server_private_key_path` from the `[node]` table.
    - Renames `server_cert_path` to `cert_path` and `server_private_key_path` to `private_key_path`.
    - Creates a new `[node.ws_server.certificates]` table to store these certificate paths.
    - Ensures that the `[node.ws_server]` table does not exist prior to migration, enforcing correct migration order.

"""

import tomlkit
from common import utils


def __migrate_move_vm_parameters(toml_data):
    utils.print_with_checkmark("Removing [move_vm] table")
    toml_data.pop("move_vm")


def __migrate_node_ws_certificates(toml_data):
    if "ws_server" in toml_data["node"]:
        raise SystemExit(
            "Error: [node.ws_server] table should not exist in before v9 config. Please check your migration path matching the version of your config file."
        )

    # Explicitly move and rename these keys from the [node] table
    # to the [node.ws_server.certificates] table
    node_ws_certificates_keys_v7_to_v9 = {
        "root_ca_cert_path": "root_ca_cert_path",
        "server_cert_path": "cert_path",
        "server_private_key_path": "private_key_path",
    }
    ws_certificates_v9 = {}

    for old_key, new_key in node_ws_certificates_keys_v7_to_v9.items():
        if old_key in toml_data["node"]:
            value = toml_data["node"].pop(old_key)
            if not value:
                print(
                    f"Warning: `{old_key}` does not exist or its value is empty. Your config must be invalid and you should check it manually after migration"
                )
            utils.print_with_checkmark(
                f"Moving `{old_key}` from [node] to {new_key} in [node.ws_server.certificates]"
            )
            ws_certificates_v9[new_key] = value
        else:
            print(f"Warning: `{old_key}` not found in [node]")

    # Create [node.ws_server.certificates] table
    toml_data["node"]["ws_server"] = tomlkit.table()
    toml_data["node"]["ws_server"]["certificates"] = tomlkit.table()
    for key, value in ws_certificates_v9.items():
        toml_data["node"]["ws_server"]["certificates"][key] = value


def migrate_v7_to_v9(toml_data):
    __migrate_move_vm_parameters(toml_data)
    __migrate_node_ws_certificates(toml_data)
