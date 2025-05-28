import click
from rpc_config.migrate_path import RPC_CONFIG_MIGRATE_PATH
from rpc_config.migrate_path import run_migration as migrate_rpc_config
from smr_settings.migrate_path import SMR_SETTINGS_MIGRATE_PATH
from smr_settings.migrate_path import run_migration as migrate_smr_config


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
def rpc(migrate_path, from_file, to_file):
    """Migrate RPC config."""
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
def smr(migrate_path, from_file, to_file):
    """Migrate SMR config."""
    migrate_smr_config(migrate_path, from_file, to_file)


@main.command()
def dump_templates():
    """Dump built-in template to TOML files."""
    from rpc_config.rpc_config_v9_1_x_mainnet_template import dump_template as dump_rpc_template
    from smr_settings.smr_settings_v9_1_x_mainnet_template import dump_template as dump_smr_template

    dump_rpc_template()
    dump_smr_template()
    print("Templates dumped successfully.")


if __name__ == "__main__":
    main()
