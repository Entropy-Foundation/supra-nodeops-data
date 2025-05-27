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

"""
import tomlkit

from .rpc_config_v9_1_x_mainnet_template import RPC_CONFIG_V9_1_X_MAINNET_TEMPLATE


def __migrate_sync_ws_parameters(v7_toml_data, v9_toml_data):
    if "synchronization" in v7_toml_data:
        raise SystemExit(
            "Error: [synchronization] table should not exist in v7 config. Please check your migration path matching the version of your config file."
        )
    v9_toml_data["synchronization"]["ws"]["consensus_rpc"] = v7_toml_data["consensus_rpc"]

    v9_toml_data["synchronization"]["ws"]["certificates"]["cert_path"] = v7_toml_data["consensus_client_cert_path"]
    v9_toml_data["synchronization"]["ws"]["certificates"]["private_key_path"] = v7_toml_data["consensus_client_private_key_path"]
    v9_toml_data["synchronization"]["ws"]["certificates"]["root_ca_cert_path"] = v7_toml_data["consensus_root_ca_cert_path"]


def __migrate_chain_state_assembler_parameters(v7_toml_data, v9_toml_data):
    if "chain_state_assembler" in v7_toml_data:
        raise SystemExit(
            "Error: [chain_state_assembler] table should not exist in v7 config."
        )
    # No changes needed for chain state assembler parameters in v9
    pass

def __migrate_bind_addr(v7_toml_data, v9_toml_data):
    v9_toml_data["bind_addr"] = v7_toml_data["bind_addr"]


def __migrate_supra_committees_config(v7_toml_data, v9_toml_data):
    v9_toml_data["supra_committees_config"] = v7_toml_data["supra_committees_config"]

def __migrate_database_paths(v7_toml_data, v9_toml_data):
    v9_toml_data["database_setup"]["dbs"]["archive"]["rocks_db"]["path"] = v7_toml_data["database_setup"]["dbs"]["archive"]["rocks_db"]["path"]
    v9_toml_data["database_setup"]["dbs"]["ledger"]["rocks_db"]["path"] = v7_toml_data["database_setup"]["dbs"]["ledger"]["rocks_db"]["path"]
    v9_toml_data["database_setup"]["dbs"]["chain_store"]["rocks_db"]["path"] = v7_toml_data["database_setup"]["dbs"]["chain_store"]["rocks_db"]["path"]

def __migrate_snapshot_paths(v7_toml_data, v9_toml_data):
    v9_toml_data["database_setup"]["snapshot_config"]["path"] = v7_toml_data["database_setup"]["snapshot_config"]["path"]


def migrate_v7_to_v9(v7_toml_data):
    """
    Returns a new TOML data structure that is compatible with RPC config v9.
    """
    v9_toml_data = tomlkit.parse(RPC_CONFIG_V9_1_X_MAINNET_TEMPLATE)
    __migrate_sync_ws_parameters(v7_toml_data, v9_toml_data)
    __migrate_chain_state_assembler_parameters(v7_toml_data, v9_toml_data)
    __migrate_bind_addr(v7_toml_data, v9_toml_data)
    __migrate_supra_committees_config(v7_toml_data, v9_toml_data)
    __migrate_database_paths(v7_toml_data, v9_toml_data)
    __migrate_snapshot_paths(v7_toml_data, v9_toml_data)
    return v9_toml_data
