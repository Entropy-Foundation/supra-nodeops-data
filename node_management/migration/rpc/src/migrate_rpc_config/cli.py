from .from_v7_to_v8 import migrate_v7_to_v8
from .from_v8_to_v9 import migrate_v8_to_v9

from . import utils
import tomlkit
from copy import deepcopy


RPC_CONFIG_MIGRATE_PATH = {
    "v7->v8": [migrate_v7_to_v8],
    "v8->v9": [migrate_v8_to_v9],
    "v7->v9": [migrate_v7_to_v8, migrate_v8_to_v9],
}


def migrate_config(migrate_path: str, from_path: str, to_path: str):
    # Get the migration functions for the given path
    migrate_functions = RPC_CONFIG_MIGRATE_PATH.pop(migrate_path)
    if not migrate_functions:
        raise SystemExit(f"Error: unsupported migration path {migrate_path}.")
    from_version = migrate_path.split("->")[0]
    to_version = migrate_path.split("->")[1]

    default_backup_path = f"{from_path}_{from_version}.bak"
    if from_path == to_path:
        print(f"Warning: The source and destination paths are the same ({from_path}).")
        print(
            f"A backup of your original config will be saved to: {default_backup_path}"
        )
        confirm = input(
            "This will overwrite your original config file. Continue? [y/N]: "
        )
        if confirm.lower() != "y":
            print("Aborted by user.")
            return

    with open(from_path, "r") as f:
        toml_data = tomlkit.parse(f.read())

    # Backup old config
    original_toml_data = deepcopy(toml_data)

    for fn in migrate_functions:
        print(f"Running migration function: {fn.__name__}")
        fn(toml_data)

    print(f"Backing up old config to {default_backup_path}")
    tomlkit.dump(original_toml_data, open(default_backup_path, "w"))

    # Write new config
    print(f"Writing new config to {to_path}")
    with open(to_path, "w") as f:
        f.write(tomlkit.dumps(toml_data))

    # Print the diff
    from_str = tomlkit.dumps(original_toml_data).splitlines(keepends=True)
    to_str = tomlkit.dumps(toml_data).splitlines(keepends=True)

    utils.unified_diff(
        from_str,
        to_str,
        fromfile=from_version,
        tofile=to_version,
    )

    print(
        f"""
    Config migrated from {from_path} to {to_path}.
    Please double check above for the diff between old and new config.
    Please ensure to use the new config file for target binary version.
    """
    )


def main():
    import argparse


    parser = argparse.ArgumentParser(
        description="Migrate RPC config.toml file from old version to new one."
    )
    choices_str = ", ".join([f"'{k}'" for k in RPC_CONFIG_MIGRATE_PATH.keys()])
    parser.add_argument(
        "-p",
        "--migrate-path",
        required=True,
        type=str,
        metavar="",
        choices=list(RPC_CONFIG_MIGRATE_PATH.keys()),
        help=f"Path to migrate the config. Choices: {choices_str}",
    )
    parser.add_argument(
        "-f",
        "--from-file",
        required=True,
        type=str,
        metavar="",
        help="Path to the old version config file to migrate",
    )
    parser.add_argument(
        "-t",
        "--to-file",
        required=True,
        type=str,
        metavar="",
        help="Path to save the migrated config file",
    )
    args = parser.parse_args()
    migrate_config(args.migrate_path, args.from_file, args.to_file)
