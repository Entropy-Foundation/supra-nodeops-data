from .migrate_v7_to_v9 import migrate_v7_to_v9

from common import migration



SMR_SETTINGS_MIGRATE_PATH = {
    "v7->v9": [migrate_v7_to_v9],
}


def migrate_config(migrate_path: str, from_path: str, to_path: str):

    migration.Migration(SMR_SETTINGS_MIGRATE_PATH).migrate_config(
        migrate_path, from_path, to_path
    )

def main():
    import argparse


    parser = argparse.ArgumentParser(
        description="Migrate validator smr_settings.toml file from old version to new one."
    )
    choices_str = ", ".join([f"'{k}'" for k in SMR_SETTINGS_MIGRATE_PATH.keys()])
    parser.add_argument(
        "-p",
        "--migrate-path",
        required=True,
        type=str,
        metavar="",
        choices=list(SMR_SETTINGS_MIGRATE_PATH.keys()),
        help=f"Migration path choices: {choices_str}",
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
