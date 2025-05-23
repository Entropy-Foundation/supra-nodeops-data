import typing as ty
import tomlkit
from copy import deepcopy
from . import utils


class MigrationPathSet:
    """
    Base class for migration paths.
    """

    def __init__(self, migrate_paths: ty.Dict[str, ty.List[ty.Callable]]):
        self.migrate_paths = migrate_paths

    def get_versions(self, key: str) -> ty.Tuple[str, str]:
        """Split the key into from_version and to_version."""
        if key not in self.migrate_paths:
            raise ValueError(f"Invalid key: {key}")
        from_version, to_version = key.split("-", 1)
        return from_version, to_version

    def get_migration_functions(self, key: str) -> ty.List[ty.Callable]:
        """Get the migration functions for the given key."""
        if key not in self.migrate_paths:
            raise ValueError(f"Unknown migration path: {key}")
        return self.migrate_paths[key]


class Migration:
    """
    Top level migration class that handles the migration of config files.
    """

    def __init__(self, migrate_path: ty.Dict[str, ty.List[ty.Callable]]):
        self.migrate_path = MigrationPathSet(migrate_path)

    def migrate_config(self, migrate_choice: str, from_path: str, to_path: str):
        migrate_functions = self.migrate_path.get_migration_functions(migrate_choice)

        from_version, to_version = self.migrate_path.get_versions(migrate_choice)
        default_backup_path = f"{from_path}_{from_version}.bak"
        if from_path == to_path:
            print(
                f"Warning: The source and destination paths are the same ({from_path})."
            )
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
        NOTE: the comments may not be preserved in the new config file, so 
        you would need to fix the comments manually.
        """
        )
