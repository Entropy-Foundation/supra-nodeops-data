"""
This module provides migration functions to upgrade a Supra RPC config file from version v8 to v9.

Key changes handled by this migration:
- Moves and renames certificate-related keys from the [synchronization.ws] table to a new [synchronization.ws.certificates] table.
    - "consensus_client_cert_path" is renamed to "cert_path"
    - "consensus_client_private_key_path" is renamed to "private_key_path"
    - "consensus_root_ca_cert_path" is renamed to "root_ca_cert_path"
- Ensures that the [synchronization] table exists and that the [synchronization.ws.certificates] table does not already exist in the v8 config.
- Warns if any expected keys are missing or have empty values, indicating potential issues with the input config.
- Provides utility output to indicate the migration steps being performed.

"""

import tomlkit
from common import utils


def __migrate_sync_ws_certificates(toml_data):
    if "synchronization" not in toml_data:
        raise SystemExit(
            "Error: [synchronization] table should exist in v8 config. Please check your migration path matching the version of your config file."
        )
    if "certificates" in toml_data["synchronization"]["ws"]:
        raise SystemExit(
            "Error: [synchronization.ws.certificates] table should not exist in v8 config. Please check your migration path matching the version of your config file."
        )

    # Explicitly move and rename these keys from the [synchronization.ws] table
    # to the [synchronization.ws.certificates] table
    sync_ws_certificates_keys_v8_to_v9 = {
        "consensus_client_cert_path": "cert_path",
        "consensus_client_private_key_path": "private_key_path",
        "consensus_root_ca_cert_path": "root_ca_cert_path",
    }

    sync_ws_certificates_v9 = {}

    for key, new_key in sync_ws_certificates_keys_v8_to_v9.items():
        if key in toml_data["synchronization"]["ws"]:
            value = toml_data["synchronization"]["ws"].pop(key)
            if not value:
                print(
                    f"Warning: `{key}` does not exist or its value is empty. Your config must be invalid and you should check it manually after migration"
                )
            utils.print_with_checkmark(
                f"Moving `{key}` from [synchronization.ws] to  {new_key} in [synchronization.ws.certificates] "
            )
            sync_ws_certificates_v9[new_key] = value
        else:
            print(f"Warning: `{key}` not found in [synchronization.ws]")

    toml_data["synchronization"]["ws"]["certificates"] = tomlkit.table()
    for key, value in sync_ws_certificates_v9.items():
        toml_data["synchronization"]["ws"]["certificates"][key] = value


def migrate_v8_to_v9(toml_data):
    __migrate_sync_ws_certificates(toml_data)
