import click
from rpc_config.migrate_path import RPC_CONFIG_MIGRATE_PATH
from rpc_config.migrate_path import run_migration as migrate_rpc_config
from smr_settings.migrate_path import SMR_SETTINGS_MIGRATE_PATH
from smr_settings.migrate_path import run_migration as migrate_smr_config
import common.globals


@click.group()
def main():
    """Migration CLI for Supra configs."""


@main.command()
@click.option(
    "--migrate-path",
    "-p",
    required=True,
    type=click.Choice(RPC_CONFIG_MIGRATE_PATH, case_sensitive=True),
    help=f"Migration path (choices: {', '.join(RPC_CONFIG_MIGRATE_PATH)})",
)
@click.option(
    "--from-file",
    "-f",
    required=True,
    type=click.Path(exists=True),
    help="Source config file",
)
@click.option(
    "--to-file", "-t", required=True, type=click.Path(), help="Output config file"
)
@click.option(
    "--assume-yes",
    "-y",
    is_flag=True,
    default=False,
    help="Assume yes for all prompts (default: False)",
)
def rpc(migrate_path, from_file, to_file, assume_yes):
    """Migrate RPC config."""
    common.globals.ASSUME_YES = assume_yes
    migrate_rpc_config(migrate_path, from_file, to_file)


@main.command()
@click.option(
    "--migrate-path",
    "-p",
    required=True,
    type=click.Choice(SMR_SETTINGS_MIGRATE_PATH, case_sensitive=True),
    help=f"Migration path (choices: {', '.join(SMR_SETTINGS_MIGRATE_PATH)})",
)
@click.option(
    "--from-file",
    "-f",
    required=True,
    type=click.Path(exists=True),
    help="Source config file",
)
@click.option(
    "--to-file", "-t", required=True, type=click.Path(), help="Output config file"
)
@click.option(
    "--assume-yes",
    "-y",
    is_flag=True,
    default=False,
    help="Assume yes for all prompts (default: False)",
)
def smr(migrate_path, from_file, to_file, assume_yes):
    """Migrate SMR config."""
    common.globals.ASSUME_YES = assume_yes
    migrate_smr_config(migrate_path, from_file, to_file)


if __name__ == "__main__":
    main()
