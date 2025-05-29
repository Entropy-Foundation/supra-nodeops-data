
### Usage Example


alias rpc-v8=~/Documents/share/repo/smr-moonshot-testnet/target/devopt/rpc_node
alias rpc-v9=~/Documents/share/repo/smr-moonshot/target/release/rpc_node

alias supra-v8="~/Documents/share/repo/smr-moonshot-testnet/target/devopt/supra"
alias supra-v9="~/Documents/share/repo/smr-moonshot/target/release/supra"


1. Install the `migrate-config` tool

```sh
pip install .
```

2. Migrate rpc

```sh
# Migrate rpc config from v7 to v9
migrate-config rpc -p v7-v9  -f config.toml -t config.toml
# Migrate db from v7 to v8
rpc-v8 migrate-db config.toml
# Migrate db from v8 to v9
rpc-v9 migrate-db config.toml
```

3. Migrate smr/validator

```sh
# Migrate cli profile from v7 to v8
supra-v8 migrate --network localnet
cp validator_identity.pem node_identity.pem
# Migrate cli profile from v8 to v9
supra-v9 profile migrate

# Migrate smr_settings from v7 to v9
migrate-config smr -p v7-v9 -f smr_settings.toml -t smr_settings.toml
# Migrate db from v7 to v9
supra-v9 data migrate -p smr_settings.toml
```


### Migrate from v7 to v9 example flow

#### RPC

1. Config migration

$ migrate-config rpc -p v7-v9 -f config.toml -t config.toml

    Running migration function: migrate_v7_to_v9

    Scanning root level configuration ...
    ✓ `consensus_access_tokens` not found in original config, using new version's default value: []
    `allowed_origin = <AoT [{'url': 'https://rpc-mainnet.supra.com', ...` is not recommended for new version.
    Do you want to apply the recommended config: `allowed_origin = <AoT [{'url': 'https://rpc-mainnet.supra.com', ...`? [y/N]: y
    ✓ Apply recommended config: `allowed_origin = <AoT [{'url': 'https://rpc-mainnet.supra.com', ...`

    Scanning chain state assembler configuration ...
    ✓ `certified_block_cache_bucket_size` not found in original config, using new version's default value: 50

    Scanning archive configuration ...
    ✓ `enable_pruning` not found in original config, using new version's default value: False
    `enable_snapshots = True` is not recommended for new version.
    Do you want to apply the recommended config: `enable_snapshots = False`? [y/N]: y
    ✓ Apply recommended config: `enable_snapshots = False`

    Scanning ledger configuration ...
    ✓ `enable_pruning` not found in original config, using new version's default value: False
    ✓ `enable_snapshots` not found in original config, using new version's default value: False

    Scanning chain store configuration ...
    ✓ `enable_pruning` not found in original config, using new version's default value: False
    `enable_snapshots = True` is not recommended for new version.
    Do you want to apply the recommended config: `enable_snapshots = False`? [y/N]: y
    ✓ Apply recommended config: `enable_snapshots = False`

    Scanning snapshot configuration ...
    Warning: [database_setup.prune_config] table not found in v7 config. Skipping migration.
    Writing new config to /tmp/newconfig.toml
    |----------------- Begin diff v7 vs v9 -----------------|
    ..
    |----------------- End diff v7 vs v9 -----------------|

          ######################################################################
          # Config migrated from tests/config_v7.1.8.toml to /tmp/newconfig.toml.
          # 
          # Please review the diff above for changes made during migration.
          # 
          # Please ensure to use the new config file for target binary version.
          ######################################################################

2. DB migration

**You need to have both v8 and v9 `rpc_node` binary to run the db migration.**

$ rpc-v8 migrate-db config.toml

    [================================================================================================================================================================================================] 100/100
    MigrationReport { drop_cf: ["tx_block_info"], migrate_kv: {"tx_block_info__txn_hash_to_block_hash": 8537} }

$ rpc-v9 migrate-db config.toml

    Counting the number of entries in certified_block...
    Migrating certified_block to certified_block_dehydrated: [00:00:00] ████████████████████ 243/243 00:00:00
    Counting the number of entries in uncommitted_block...
    Preparing to clean up uncommitted_block: [00:00:00] ████████████████████ 244/244 00:00:00
    Cleaning up uncommitted_block: [00:00:00] ████████████████████ 0/0 00:00:00
    Counting the number of entries in certified_block...
    Counting the number of entries in certified_block_dehydrated...
    Counting the number of entries in uncommitted_block...
    Counting the number of entries in qc...
    Verifying certified_block_dehydrated: [00:00:00] ████████████████████ 244/244 00:00:00
    Counting the number of entries to remove from prune_index...
    Cleaning up prune index: [00:00:00] ████████████████████ 244/244 00:00:00
    Counting the number of entries in block_to_transaction...
    Migrating block_to_transaction: [00:00:00] ████████████████████ 8537/8537 00:00:00
    dropped:
    - certified_block
    - block_to_tx
    migrated:
      block_to_tx -> block_to_tx_ordered: Migrated 8537 records, up to 239 block height
      certified_block -> certified_block_dehydrated: Migrated 244 records, up to 244 block height
    databases_checked:
    - chain_store
    - archive

#### SMR

1. Profile/Identity migration

**You need both v8 and v9 supra binary to run the profile migratino.**

$ supra-v8 migrate --network mainnet

$ cp validator_identity.pem node_identity.pem

$ supra-v9 profile migrate

2. Config migration

$ migrate-config smr -p v7-v9 -f smr_settings.toml -t smr_settings.toml

    Running migration function: migrate_v7_to_v9

    Scanning node root configuration ...
    `connection_refresh_timeout_sec = 2` is not recommended for new version.
    Do you want to apply the recommended config: `connection_refresh_timeout_sec = 1`? [y/N]: y
    ✓ Apply recommended config: `connection_refresh_timeout_sec = 1`

    Scanning ledger configuration ...
    ✓ `enable_pruning` not found in original config, using new version's default value: True
    ✓ `enable_snapshots` not found in original config, using new version's default value: False

    Scanning chain store configuration ...
    ✓ `enable_snapshots` not found in original config, using new version's default value: False

    Scanning prune configuration ...

    Scanning mempool configuration ...
    `max_batch_delay_ms = 1500` is not recommended for new version.
    Do you want to apply the recommended config: `max_batch_delay_ms = 500`? [y/N]: y
    ✓ Apply recommended config: `max_batch_delay_ms = 500`

    Scanning moonshot configuration ...
    `message_recency_bound_rounds = 20` is not recommended for new version.
    Do you want to apply the recommended config: `message_recency_bound_rounds = 1000`? [y/N]: y
    ✓ Apply recommended config: `message_recency_bound_rounds = 1000`
    `sync_retry_delay_ms = 2000` is not recommended for new version.
    Do you want to apply the recommended config: `sync_retry_delay_ms = 1000`? [y/N]: y
    ✓ Apply recommended config: `sync_retry_delay_ms = 1000`
    `timeout_delay_ms = 5000` is not recommended for new version.
    Do you want to apply the recommended config: `timeout_delay_ms = 3500`? [y/N]: y
    ✓ Apply recommended config: `timeout_delay_ms = 3500`
    Writing new config to /tmp/new_smr.toml
    |----------------- Begin diff v7 vs v9 -----------------|
    --- v7
    +++ v9
    ..
    |----------------- End diff v7 vs v9 -----------------|

            ######################################################################
            # Config migrated from tests/smr_settings_v7.1.x.toml to /tmp/new_smr.toml.
            # 
            # Please review the diff above for changes made during migration.
            # 
            # Please ensure to use the new config file for target binary version.
            ######################################################################

3. DB migration

**You need v9 supra binary to run the db migration.**

$ supra-v9 data migrate -p smr_settings.toml

    Counting the number of entries in certified_block...
    Migrating certified_block to certified_block_dehydrated: [00:00:00] ████████████████████ 69/69 00:00:00
    Counting the number of entries in uncommitted_block...
    Preparing to clean up uncommitted_block: [00:00:00] ████████████████████ 74/74 00:00:00
    Cleaning up uncommitted_block: [00:00:00] ████████████████████ 4/4 00:00:00
    Counting the number of entries in certified_block...
    Counting the number of entries in certified_block_dehydrated...
    Counting the number of entries in uncommitted_block...
    Counting the number of entries in qc...
    Verifying certified_block_dehydrated: [00:00:00] ████████████████████ 70/70 00:00:00
    Counting the number of entries to remove from prune_index...
    Cleaning up prune index: [00:00:00] ████████████████████ 70/70 00:00:00
    dropped:
    - certified_block
    migrated:
      certified_block -> certified_block_dehydrated: Migrated 70 records, up to 244 block height
    databases_checked:
    - chain_store


### Test harness of migrate-config script

`PYTHONPATH=src pytest`