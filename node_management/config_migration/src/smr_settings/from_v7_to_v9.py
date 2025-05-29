"""
This module provides migration utilities to upgrade Supra's Validator configuration files from version v7 to v9.

Migration Steps:
----------------
- Loads a v9 template configuration as the migration base.
- Migrates root-level fields such as rpc_access_port and certificate paths.
- Migrates database paths for chain store and ledger components.
- Migrates snapshot configuration paths if present; skips if not found in v7.
- Migrates prune configuration if present; skips if not found in v7.
- Migrates mempool and moonshot sections, preserving all settings.
- For each section, scans and recommends updates for any legacy fields.
- Exit early if any unexpected sections in v7 (e.g., [node.ws_server]) are present before migration.

The main entrypoint is `migrate_v7_to_v9(v7_toml_data)`, which returns a new TOML data structure compatible with v9.

"""

import tomlkit
import importlib.resources
from common.utils import scan_and_recommend_updates

def __migrate_node_root_config(v7_toml_data, v9_toml_data):
    if "ws_server" in v7_toml_data["node"]:
        raise SystemExit(
            "Error: [node.ws_server] table should not exist in v7 config. Please check your migration path matching the version of your config file."
        )

    v9_node_data = v9_toml_data["node"]
    v7_node_data = v7_toml_data["node"]
    v9_node_data["rpc_access_port"] = v7_node_data["rpc_access_port"]

    v9_node_ws_certificates = v9_node_data["ws_server"]["certificates"]
    v9_node_ws_certificates["root_ca_cert_path"] = v7_node_data["root_ca_cert_path"]
    v9_node_ws_certificates["cert_path"] = v7_node_data["server_cert_path"]
    v9_node_ws_certificates["private_key_path"] = v7_node_data["server_private_key_path"]

    print("\nScanning node root configuration ...")
    scan_and_recommend_updates(v7_node_data, v9_node_data)


def __migrate_db_chain_store(v7_toml_data, v9_toml_data):
    v9_db_chain_store = v9_toml_data["node"]["database_setup"]["dbs"]["chain_store"]["rocks_db"]
    v7_db_chain_store = v7_toml_data["node"]["database_setup"]["dbs"]["chain_store"]["rocks_db"]
    v9_db_chain_store["path"] = v7_db_chain_store["path"]

    print("\nScanning chain store configuration ...")
    scan_and_recommend_updates(v7_db_chain_store, v9_db_chain_store)

def __migrate_db_ledger(v7_toml_data, v9_toml_data):
    v9_db_ledger = v9_toml_data["node"]["database_setup"]["dbs"]["ledger"]["rocks_db"]
    v7_db_ledger = v7_toml_data["node"]["database_setup"]["dbs"]["ledger"]["rocks_db"]
    v9_db_ledger["path"] = v7_db_ledger["path"]

    print("\nScanning ledger configuration ...")
    scan_and_recommend_updates(v7_db_ledger, v9_db_ledger)

def __migrate_snapshot_config(v7_toml_data, v9_toml_data):
    """
    snapshot_config is optional,
    - if absent in v7, the v9 config template will be used as is.
    """
    if "snapshot_config" not in v7_toml_data["node"]["database_setup"]:
        return
    
    if "snapshot_config" not in v9_toml_data["node"]["database_setup"]:
        raise SystemExit(
            "Error: [node.database_setup.snapshot_config] table should exist in v9 template."
        )

    v9_snapshot_config = v9_toml_data["node"]["database_setup"]["snapshot_config"]
    v7_snapshot_config = v7_toml_data["node"]["database_setup"]["snapshot_config"]

    v9_snapshot_config["path"] = v7_snapshot_config["path"]

    print("\nScanning snapshot configuration ...")
    scan_and_recommend_updates(v7_snapshot_config, v9_snapshot_config)

def __migrate_prune_config(v7_toml_data, v9_toml_data):
    """
    prune_config is optional, so we skip if it does not exist in v7.
    """
    if "prune_config" not in v7_toml_data["node"]["database_setup"]:
        return
    
    if "prune_config" not in v9_toml_data["node"]["database_setup"]:
        raise SystemExit(
            "Error: [node.database_setup.prune_config] table should exist in v9 template."
        )

    v9_prune_config = v9_toml_data["node"]["database_setup"]["prune_config"]
    v7_prune_config = v7_toml_data["node"]["database_setup"]["prune_config"]

    print("\nScanning prune configuration ...")
    scan_and_recommend_updates(v7_prune_config, v9_prune_config)


def __migrate_mempool_config(v7_toml_data, v9_toml_data):

    v9_mempool_config = v9_toml_data["mempool"]
    v7_mempool_config = v7_toml_data["mempool"]

    print("\nScanning mempool configuration ...")
    scan_and_recommend_updates(v7_mempool_config, v9_mempool_config)

def __migrate_moonshot_config(v7_toml_data, v9_toml_data):
    v9_moonshot_config = v9_toml_data["moonshot"]
    v7_moonshot_config = v7_toml_data["moonshot"]

    print("\nScanning moonshot configuration ...")
    scan_and_recommend_updates(v7_moonshot_config, v9_moonshot_config)

def migrate_v7_to_v9(v7_toml_data):
    """
    Returns a new TOML data structure that is compatible with SMR settings v9.
    """
    with (
        importlib.resources.files(__package__)
        .joinpath("smr_settings_v9_1_x_mainnet_template.toml")
        .open("r") as f
    ):
        template = f.read()
    v9_toml_data = tomlkit.parse(template)
    __migrate_node_root_config(v7_toml_data, v9_toml_data)
    __migrate_db_ledger(v7_toml_data, v9_toml_data)
    __migrate_db_chain_store(v7_toml_data, v9_toml_data)
    __migrate_snapshot_config(v7_toml_data, v9_toml_data)
    __migrate_prune_config(v7_toml_data, v9_toml_data)
    __migrate_mempool_config(v7_toml_data, v9_toml_data)
    __migrate_moonshot_config(v7_toml_data, v9_toml_data)
    return v9_toml_data
