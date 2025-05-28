import typing as ty
import tomlkit
from copy import deepcopy
from . import utils
import shutil
from common.globals import ASSUME_YES
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
            confirm = utils.prompt_or_assume_yes(
                "This will overwrite your original config file. Continue?",
                ASSUME_YES
            )
            if not confirm:
                print("Aborted by user.")
                return
            # Backup old config
            print(f"Backing up old config to {default_backup_path}")
            shutil.copyfile(from_path, default_backup_path)

        with open(from_path, "r") as f:
            toml_data = tomlkit.load(f)

        original_toml_data = deepcopy(toml_data)

        for fn in migrate_functions:
            print(f"Running migration function: {fn.__name__}")
            toml_data = fn(toml_data)


        # Write new config
        print(f"Writing new config to {to_path}")
        with open(to_path, "w") as f:
            tomlkit.dump(toml_data, f)
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
        ######################################################################
        # Config migrated from {from_path} to {to_path}.
        # 
        # Please review the diff above for changes made during migration.
        # 
        # Please ensure to use the new config file for target binary version.
        ######################################################################
        """
        )
