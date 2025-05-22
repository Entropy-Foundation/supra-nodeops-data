from .from_v7_to_v9 import migrate_v7_to_v9

from common import migration



SMR_SETTINGS_MIGRATE_PATH = {
    "v7-v9": [migrate_v7_to_v9],
}


def run_migration(migrate_path: str, from_path: str, to_path: str):

    migration.Migration(SMR_SETTINGS_MIGRATE_PATH).migrate_config(
        migrate_path, from_path, to_path
    )

