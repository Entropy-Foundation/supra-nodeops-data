"""
This module provides migration utilities to upgrade Supra's RPC configuration files from version v7 to v9.

Migration Steps:
----------------
- Loads a v9 template configuration as the migration base.
- Migrates root-level fields such as 'supra_committees_config' and 'bind_addr'.
- Migrates synchronization WebSocket settings, including consensus RPC and certificate paths.
- Migrates chain state assembler configuration.
- Migrates database paths for archive, chain store, and ledger components.
- Migrates snapshot configuration paths.
- For each section, scans and recommends updates for any legacy fields.
- Ensures that deprecated or unexpected sections in v7 (e.g., 'synchronization', 'chain_state_assembler') are flagged as errors.

The main entrypoint is `migrate_v7_to_v9(v7_toml_data)`, which returns a new TOML data structure compatible with v9.
This module provides migration functions to upgrade Supra's RPC configuration from version v7 to v9.

"""

import tomlkit
import importlib.resources
from common.utils import (
    scan_and_recommend_updates,
)


def __migrate_root_config(v7_toml_data, v9_toml_data):
    v9_toml_data["supra_committees_config"] = v7_toml_data["supra_committees_config"]

    v9_toml_data["bind_addr"] = v7_toml_data["bind_addr"]

    print("\nScanning root level configuration ...")
    scan_and_recommend_updates(v7_toml_data, v9_toml_data)


def __migrate_sync_ws_config(v7_toml_data, v9_toml_data):
    if "synchronization" in v7_toml_data:
        raise SystemExit(
            "Error: [synchronization] table should not exist in v7 config. Please check your migration path matching the version of your config file."
        )
    v9_sync_ws_config = v9_toml_data["synchronization"]["ws"]
    v9_sync_ws_config["consensus_rpc"] = v7_toml_data["consensus_rpc"]

    v9_sync_ws_certificates = v9_sync_ws_config["certificates"]
    v9_sync_ws_certificates["cert_path"] = v7_toml_data["consensus_client_cert_path"]
    v9_sync_ws_certificates["private_key_path"] = v7_toml_data[
        "consensus_client_private_key_path"
    ]
    v9_sync_ws_certificates["root_ca_cert_path"] = v7_toml_data[
        "consensus_root_ca_cert_path"
    ]


def __migrate_chain_state_assembler_config(v7_toml_data, v9_toml_data):
    if "chain_state_assembler" in v7_toml_data:
        raise SystemExit(
            "Error: [chain_state_assembler] table should not exist in v7 config."
        )

    print("\nScanning chain state assembler configuration ...")
    scan_and_recommend_updates(v7_toml_data, v9_toml_data["chain_state_assembler"])


def __migrate_db_archive_config(v7_toml_data, v9_toml_data):
    v9_db_archive_config = v9_toml_data["database_setup"]["dbs"]["archive"]["rocks_db"]
    v7_db_archive_config = v7_toml_data["database_setup"]["dbs"]["archive"]["rocks_db"]

    v9_db_archive_config["path"] = v7_db_archive_config["path"]

    print("\nScanning archive configuration ...")
    scan_and_recommend_updates(v7_db_archive_config, v9_db_archive_config)


def __migrate_db_chain_store_config(v7_toml_data, v9_toml_data):
    v9_db_chain_store_config = v9_toml_data["database_setup"]["dbs"]["chain_store"][
        "rocks_db"
    ]
    v7_db_chain_store_config = v7_toml_data["database_setup"]["dbs"]["chain_store"][
        "rocks_db"
    ]

    v9_db_chain_store_config["path"] = v7_db_chain_store_config["path"]

    print("\nScanning chain store configuration ...")
    scan_and_recommend_updates(v7_db_chain_store_config, v9_db_chain_store_config)


def __migrate_db_ledger_config(v7_toml_data, v9_toml_data):
    v9_db_ledger_config = v9_toml_data["database_setup"]["dbs"]["ledger"]["rocks_db"]
    v7_db_ledger_config = v7_toml_data["database_setup"]["dbs"]["ledger"]["rocks_db"]
    v9_db_ledger_config["path"] = v7_db_ledger_config["path"]
    print("\nScanning ledger configuration ...")
    scan_and_recommend_updates(v7_db_ledger_config, v9_db_ledger_config)


def __migrate_snapshot_config(v7_toml_data, v9_toml_data):
    # Optional config
    if "snapshot_config" not in v7_toml_data["database_setup"]:
        print(
            "Warning: [database_setup.snapshot_config] table not found in v7 config. Skipping migration."
        )
        return
    if "snapshot_config" not in v9_toml_data["database_setup"]:
        raise SystemExit(
            "Error: [database_setup.snapshot_config] table should exist in v9 template."
        )
        
    v9_snapshot_config = v9_toml_data["database_setup"]["snapshot_config"]
    v7_snapshot_config = v7_toml_data["database_setup"]["snapshot_config"]

    v9_snapshot_config["path"] = v7_snapshot_config["path"]

    print("\nScanning snapshot configuration ...")
    scan_and_recommend_updates(v7_snapshot_config, v9_snapshot_config)


def __migrate_prune_config(v7_toml_data, v9_toml_data):
    # Optional config
    if "prune_config" not in v7_toml_data["database_setup"]:
        print(
            "Warning: [database_setup.prune_config] table not found in v7 config. Skipping migration."
        )
        return
    if "prune_config" not in v9_toml_data["database_setup"]:
        raise SystemExit(
            "Error: [database_setup.prune_config] table should exist in v9 template."
        )
    v9_prune_config = v9_toml_data["database_setup"]["prune_config"]
    v7_prune_config = v7_toml_data["database_setup"]["prune_config"]

    print("\nScanning prune configuration ...")
    scan_and_recommend_updates(v7_prune_config, v9_prune_config)


def migrate_v7_to_v9(v7_toml_data):
    """
    Returns a new TOML data structure that is compatible with RPC config v9.
    """

    with (
        importlib.resources.files(__package__)
        .joinpath("rpc_config_v9_1_x_mainnet_template.toml")
        .open("r") as f
    ):
        template = f.read()
    v9_toml_data = tomlkit.parse(template)
    __migrate_root_config(v7_toml_data, v9_toml_data)
    __migrate_sync_ws_config(v7_toml_data, v9_toml_data)
    __migrate_chain_state_assembler_config(v7_toml_data, v9_toml_data)
    __migrate_db_archive_config(v7_toml_data, v9_toml_data)
    __migrate_db_ledger_config(v7_toml_data, v9_toml_data)
    __migrate_db_chain_store_config(v7_toml_data, v9_toml_data)
    __migrate_snapshot_config(v7_toml_data, v9_toml_data)
    __migrate_prune_config(v7_toml_data, v9_toml_data)
    return v9_toml_data
