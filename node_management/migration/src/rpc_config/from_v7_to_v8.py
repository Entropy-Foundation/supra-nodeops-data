"""
This module provides migration functions to upgrade Supra's RPC configuration from version 7 (v7) to version 8 (v8).

Migration Overview:
-------------------
The migration process involves restructuring and updating the configuration TOML data to match the v8 schema. The key changes performed by this migration are:

1. Synchronization Parameters:
    - Moves the following keys from the root level to a new `[synchronization.ws]` table:
      - `consensus_rpc`
      - `consensus_client_cert_path`
      - `consensus_client_private_key_path`
      - `consensus_root_ca_cert_path`
    - Raises an error if a `[synchronization]` table already exists in the v7 config.

2. Chain State Assembler Parameters:
    - Moves `sync_retry_interval_in_secs` from the root level to a new `[chain_state_assembler]` table.
    - Ensures `sync_retry_interval_in_secs` is set to `1` as recommended.
    - Adds a new parameter `certified_block_cache_bucket_size = 50` to `[chain_state_assembler]`.
    - Raises an error if a `[chain_state_assembler]` table already exists in the v7 config.

3. Consensus Access Tokens:
    - Adds a new root-level parameter: `consensus_access_tokens = []`.

4. Block Provider Trust:
    - Adds a new root-level parameter: `block_provider_is_trusted = True`.

Warnings and Checks:
--------------------
- Issues warnings if expected keys are missing or have empty values.
- Uses utility functions to print migration steps with checkmarks for better traceability.

"""

import tomlkit
from common import utils


def __migrate_sync_ws_parameters(toml_data):
    # v7 config should not have a [synchronization] table
    if "synchronization" in toml_data:
        raise SystemExit(
            "Error: [synchronization] table should not exist in v7 config. Please check your migration path matching the version of your config file."
        )

    # Explicitly fetch and move these keys from the root
    # level to the [synchronization.ws] table
    sync_ws_keys = {
        "consensus_rpc": None,
        "consensus_client_cert_path": None,
        "consensus_client_private_key_path": None,
        "consensus_root_ca_cert_path": None,
    }
    for key in sync_ws_keys:
        if key in toml_data:
            value = toml_data.pop(key)
            if not value:
                print(
                    f"Warning: `{key}` does not exist or its value is empty. Your config must be invalid and you should check it manually after migration"
                )
            utils.print_with_checkmark(
                f"Moving `{key}` from root level to [synchronization.ws]"
            )
            sync_ws_keys[key] = value
        else:
            print(f"Warning: `{key}` not found in root level")
    # Create [synchronization.ws] table
    sync_table = tomlkit.table()
    for key, value in sync_ws_keys.items():
        sync_table[key] = value
    toml_data["synchronization"] = tomlkit.table()
    toml_data["synchronization"]["ws"] = sync_table


def __migrate_chain_state_assembler_parameters(toml_data):
    # v7 config should not have a [chain_state_assembler] table
    if "chain_state_assembler" in toml_data:
        raise SystemExit(
            "Error: [chain_state_assembler] table should not exist in v7 config."
        )

    # Explicitly fetch and move these keys from the root
    # level to the [chain_state_assembler] table
    chain_assembler_keys = {
        "sync_retry_interval_in_secs": None,
    }
    for key in chain_assembler_keys:
        if key in toml_data:
            value = toml_data.pop(key)
            if not value:
                print(
                    f"Warning: `{key}` does not exist or its value is empty. Your config must be invalid and you should check it manually after migration"
                )
            utils.print_with_checkmark(
                f"Moving `{key}` from root level to [chain_state_assembler]"
            )
            if value != 1:
                print(
                    f"Warning: `{key} = {value}`, will be set to `1` as recommended by Supra."
                )
                value = 1
            chain_assembler_keys[key] = value
        else:
            print(f"Warning: `{key}` not found in root level")

    # Create [chain_state_assembler] table
    chain_assembler_table = tomlkit.table()
    for key, value in chain_assembler_keys.items():
        chain_assembler_table[key] = value
    new_parameters = {"certified_block_cache_bucket_size": 50}
    for key, value in new_parameters.items():
        utils.print_with_checkmark(
            f"Adding `{key} = {value}` to [chain_state_assembler]"
        )
        chain_assembler_table[key] = value
    toml_data["chain_state_assembler"] = chain_assembler_table


def __add_consensus_access_tokens(toml_data):
    new_parameters = {"consensus_access_tokens": []}
    for key, value in new_parameters.items():
        utils.print_with_checkmark(f"Adding `{key} = {value}` to root level")
        toml_data[key] = value


def __update_block_provider_is_trusted(toml_data):
    value = True
    utils.print_with_checkmark(
        f"Adding `block_provider_is_trusted = {value}` to root level"
    )
    toml_data["block_provider_is_trusted"] = value


def migrate_v7_to_v8(toml_data):
    # Migrate the config
    __migrate_sync_ws_parameters(toml_data)
    __migrate_chain_state_assembler_parameters(toml_data)
    __add_consensus_access_tokens(toml_data)
    __update_block_provider_is_trusted(toml_data)
