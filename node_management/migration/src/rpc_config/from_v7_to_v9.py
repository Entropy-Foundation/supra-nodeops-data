"""
This module provides migration functions to upgrade Supra's RPC configuration from version v7 to v9.

Migration Overview:
-------------------
The migration process involves restructuring and updating the configuration TOML data to match the v9 schema. The key changes performed by this migration are:

1. Synchronization Parameters:
    - Copy the following key value from v7 root level to a new `[synchronization.ws]` table in the v9 template:
      - `consensus_rpc`
    - Copy the following keys' values from v7 root level to the `[synchronization.ws.certificates]` table in v9 template:
      - from `consensus_client_cert_path` to `cert_path`
      - from `consensus_client_private_key_path` to `private_key_path`
      - from `consensus_root_ca_cert_path` to `root_ca_cert_path`
    - Raises an error if a `[synchronization]` table already exists in the v7 config.

2. Chain State Assembler Parameters:
    - Raises an error if a `[chain_state_assembler]` table already exists in the v7 config.

3. Copy value from 7 to v9 template in same table:
    - bind_addr
    - supra_committees_config
    - [database_setup.dbs.archive.rocks_db].path
    - [database_setup.dbs.ledger.rocks_db].path
    - [database_setup.dbs.chain_store.rocks_db].path
    - [[database_setup.snapshot_config]].path

4.  recommended updates
    - `sync_retry_interval_in_secs`
    - `block_provider_is_trusted`
    - `enable_snapshots`
    - `enable_pruning`
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
    v9_toml_data["database_setup"]["dbs"]["ledger"]["rocks_db"]["path"] = v7_toml_data[
        "database_setup"
    ]["dbs"]["ledger"]["rocks_db"]["path"]


def __migrate_snapshot_config(v7_toml_data, v9_toml_data):
    v9_snapshot_config = v9_toml_data["database_setup"]["snapshot_config"]
    v7_snapshot_config = v7_toml_data["database_setup"]["snapshot_config"]

    v9_snapshot_config["path"] = v7_snapshot_config["path"]

    print("\nScanning snapshot configuration ...")
    scan_and_recommend_updates(v7_snapshot_config, v9_snapshot_config)


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
    return v9_toml_data
