"""
Migration script for upgrading Supra smr_settings config files from version v7 to v9.

This module provides functions to transform configuration files in TOML format to be compatible with v9.
The migration includes the following changes:

1. Migration of WebSocket server certificate paths:
    - Copy below keys in v7 [node] table to the `[node.ws_server.certificates]` table in v9:
        - from `root_ca_cert_path` to `root_ca_cert_path`
        - from `server_cert_path` to `cert_path`
        - from `server_private_key_path` to `private_key_path`
    - Ensures that the `[node.ws_server]` table does not exist prior to migration, enforcing correct migration order.
2. Copy value from 7 to v9 template in same table:
    - [node].rpc_access_port
    - [node.database_setup.dbs.chain_store.rocks_db].path
    - [node.database_setup.dbs.ledger.rocks_db].path
"""

import tomlkit
import importlib.resources

def __migrate_ws_certificates(v7_toml_data, v9_toml_data):
    if "ws_server" in v7_toml_data["node"]:
        raise SystemExit(
            "Error: [node.ws_server] table should not exist in v7 config. Please check your migration path matching the version of your config file."
        )

    v7_node_data = v7_toml_data["node"]
    
    v9_toml_data["node"]["ws_server"]["certificates"]["root_ca_cert_path"] = v7_node_data.get("root_ca_cert_path")
    v9_toml_data["node"]["ws_server"]["certificates"]["cert_path"] = v7_node_data.get("server_cert_path")
    v9_toml_data["node"]["ws_server"]["certificates"]["private_key_path"] = v7_node_data.get("server_private_key_path")


def __migrate_rpc_access_port(v7_toml_data, v9_toml_data):
    v9_toml_data["node"]["rpc_access_port"] = v7_toml_data["node"].get("rpc_access_port")

def __migrate_database_paths(v7_toml_data, v9_toml_data):
    v9_toml_data["node"]["database_setup"]["dbs"]["chain_store"]["rocks_db"]["path"] = v7_toml_data["node"]["database_setup"]["dbs"]["chain_store"]["rocks_db"].get("path")
    v9_toml_data["node"]["database_setup"]["dbs"]["ledger"]["rocks_db"]["path"] = v7_toml_data["node"]["database_setup"]["dbs"]["ledger"]["rocks_db"].get("path")

def migrate_v7_to_v9(toml_data):
    """
    Returns a new TOML data structure that is compatible with SMR settings v9.
    """
    with importlib.resources.files(__package__).joinpath("smr_settings_v9_1_x_mainnet_template.toml").open("r") as f:
        template = f.read()
    v9_toml_data = tomlkit.parse(template)
    __migrate_ws_certificates(toml_data, v9_toml_data)
    __migrate_rpc_access_port(toml_data, v9_toml_data)
    __migrate_database_paths(toml_data, v9_toml_data)
    return v9_toml_data
