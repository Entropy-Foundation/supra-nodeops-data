from .from_v7_to_v8 import migrate_v7_to_v8
from .from_v8_to_v9 import migrate_v8_to_v9

from common import migration



RPC_CONFIG_MIGRATE_PATH = {
    "v7-v8": [migrate_v7_to_v8],
    "v8-v9": [migrate_v8_to_v9],
    "v7-v9": [migrate_v7_to_v8, migrate_v8_to_v9],
}


def run_migration(migrate_path: str, from_path: str, to_path: str):
    
    migration.Migration(RPC_CONFIG_MIGRATE_PATH).migrate_config(
        migrate_path, from_path, to_path
    )

