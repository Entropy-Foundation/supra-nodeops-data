import os
import shutil
import tomlkit
import pytest
from smr_settings.migrate_path import run_migration as smr_run_migration



@pytest.mark.parametrize(
    "from_file,to_file,migrate_path",
    [
        ("smr_settings_v7.1.x.toml", "smr_settings_v7_to_v9_expected.toml", "v7-v9"),
    ],
)
def test_migration(tmp_path, from_file, to_file, migrate_path):
    # Copy config files to temp dir
    src_dir = os.path.dirname(os.path.abspath(__file__))
    from_path = os.path.join(src_dir, from_file)
    to_path = os.path.join(src_dir, to_file)
    tmp_from = tmp_path / from_file
    tmp_to = tmp_path / to_file
    shutil.copy(from_path, tmp_from)
    # Run migration
    smr_run_migration(migrate_path, str(tmp_from), str(tmp_to))
    # Load both files
    with open(tmp_to, "r") as f:
        migrated = tomlkit.parse(f.read())
    with open(to_path, "r") as f:
        expected = tomlkit.parse(f.read())
    # Compare TOML dicts
    assert migrated == expected, (
        f"Migration {migrate_path} failed: {from_file} -> {to_file}"
    )
