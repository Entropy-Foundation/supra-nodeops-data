from copy import deepcopy

import tomlkit

def print_colored_diff(diff):
    # The color is added here manually using ANSI escape codes.
    for line in diff:
        if line.startswith('+') and not line.startswith('+++'):
            print(f"\033[32m{line}\033[0m", end='')  # Green for additions
        elif line.startswith('-') and not line.startswith('---'):
            print(f"\033[31m{line}\033[0m", end='')  # Red for deletions
        elif line.startswith('@@'):
            print(f"\033[36m{line}\033[0m", end='')  # Cyan for hunk headers
        else:
            print(line, end='')

def migrate_sync_ws_parameters(toml_data):
    # v7 config should not have a [synchronization] table
    if "synchronization" in toml_data:
        raise SystemExit(
            "Error: [synchronization] table should not exist in v7 config."
        )

    # Explicitly fetch and move these keys from the root
    # level to the [synchronization.ws] table
    sync_ws_parameters = {
        "consensus_rpc": None,
        "consensus_client_cert_path": None,
        "consensus_client_private_key_path": None,
        "consensus_root_ca_cert_path": None,
    }
    for key in sync_ws_parameters:
        if key in toml_data:
            value = toml_data.pop(key)
            if value is None:
                print(
                    f"Warning: `{key}` does not exist or its value is None, your config must be invalid and you should check it manually after migration"
                )
                continue
            else:
                print(f"Moving `{key}` from root level to [synchronization.ws]")
                sync_ws_parameters[key] = value
        else:
            print(f"Warning: `{key}` not found in root level")
    # Create [synchronization.ws] table
    sync_table = tomlkit.table()
    for key, value in sync_ws_parameters.items():
        sync_table[key] = value
    toml_data["synchronization"] = tomlkit.table()
    toml_data["synchronization"]["ws"] = sync_table


def migrate_chain_state_assembler_parameters(toml_data):
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
            if value is None:
                print(
                    f"Warning: `{key}` does not exist or its value is None, your config must be invalid and you should check it manually after migration"
                )
                continue
            else:
                print(f"Moving `{key}` from root level to [chain_state_assembler]")
                if value != 1:
                    print(
                        f"Warning: `{key}` value is {value}, will be set to `1` as recommended by Supra."
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
        print(f"Adding `{key} = {value}` to [chain_state_assembler]")
        chain_assembler_table[key] = value
    toml_data["chain_state_assembler"] = chain_assembler_table


def add_new_root_parameters(toml_data):
    new_parameters = {"consensus_access_tokens": []}
    for key, value in new_parameters.items():
        print(f"Adding `{key} = {value}` to root level")
        toml_data[key] = value


def migrate_config(old_path: str, new_path: str):
    with open(old_path, "r") as f:
        toml_data = tomlkit.parse(f.read())

    # Backup old config
    toml_data_v7 = deepcopy(toml_data)

    # Do migrations
    migrate_sync_ws_parameters(toml_data)
    migrate_chain_state_assembler_parameters(toml_data)
    add_new_root_parameters(toml_data)

    # Write new config
    with open(new_path, "w") as f:
        f.write(tomlkit.dumps(toml_data))

    print(
        f"Config migrated from {args.v7} to {args.v8}.\nPlease check the new config file for any additional changes.\n"
    )

    # Print the diff
    print("Diff between v7 and v8 config:")
    v7_str = tomlkit.dumps(toml_data_v7).splitlines(keepends=True)
    v8_str = tomlkit.dumps(toml_data).splitlines(keepends=True)
    import difflib

    diff = difflib.unified_diff(v7_str, v8_str, fromfile="v7", tofile="v8")
    print_colored_diff(diff)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Migrate RPC config from v7 to v8")
    parser.add_argument(
        "--v7", required=True, type=str, help="Path to the v7 config file"
    )
    parser.add_argument(
        "--v8", required=True, type=str, help="Path to save the v8 config file"
    )
    args = parser.parse_args()
    assert args.v7 != args.v8, "Error: v7 and v8 config paths must be different"
    migrate_config(args.v7, args.v8)
