import os
import shutil
import tempfile
import tomlkit
import pytest
from rpc_config.migrate_path import run_migration as rpc_run_migration

CONFIGS = [
    "config_v7.1.8.toml",
    "config_v8.0.2.toml",
    "config_v9.0.7.toml",
]

@pytest.mark.parametrize("from_file,to_file,migrate_path", [
    ("config_v7.1.8.toml", "config_v8.0.2.toml", "v7-v8"),
    ("config_v8.0.2.toml", "config_v9.0.7.toml", "v8-v9"),
    ("config_v7.1.8.toml", "config_v9.0.7.toml", "v7-v9"),
])
def test_migration(tmp_path, from_file, to_file, migrate_path):
    # Copy config files to temp dir
    src_dir = os.path.dirname(os.path.abspath(__file__))
    from_path = os.path.join(src_dir, from_file)
    to_path = os.path.join(src_dir, to_file)
    tmp_from = tmp_path / from_file
    tmp_to = tmp_path / to_file
    shutil.copy(from_path, tmp_from)
    # Run migration
    rpc_run_migration(migrate_path, str(tmp_from), str(tmp_to))
    # Load both files
    with open(tmp_to, "r") as f:
        migrated = tomlkit.parse(f.read())
    with open(to_path, "r") as f:
        expected = tomlkit.parse(f.read())
 
    # if "allowed_origin" in migrated:
    #     del migrated["allowed_origin"]
    # if "allowed_origin" in expected:
    #     del expected["allowed_origin"]

    
    # if "chain_instance" in migrated:
    #     del migrated["chain_instance"]
    # if "chain_instance" in expected:
    #     del expected["chain_instance"]
    # Compare TOML dicts
    assert migrated == expected, f"Migration {migrate_path} failed: {from_file} -> {to_file}"
