
### Usage 

```sh
# If you have not installed poetry, install below
pip install poetry

# Install migrate-rpc-config
cd rpc
poetry install 

# From v7 to v8
poetry run migrate-rpc-config -f config.toml -t config.toml -p 'v7->v8'

# From v8 to v9
poetry run migrate-rpc-config -f config.toml -t config.toml -p 'v8->v9'

# From v7 to v9 
poetry run migrate-rpc-config -f config.toml -t config.toml -p 'v7->v9'

# Install migrate-rpc-config
cd smr
poetry install 

poetry run migrate-smr-settings
```

#### v9 template
https://testnet-snapshot.supra.com/configs/config_v9.0.7.toml
https://testnet-snapshot.supra.com/configs/smr_settings.toml

#### v8 template
https://testnet-snapshot.supra.com/configs/config_v8.0.2.toml

#### v7 template
https://mainnet-data.supra.com/configs/config.toml



### Migrate from v7 to v9


#### rpc
migrate-rpc-config -f config.toml -t config.toml -p 'v7->v9'

(e2e-tests) kaiqichen@Mac:~/Documents/share/repo/smr-moonshot-mainnet/remote_env/Logs/rpc_0$ rpc-v8 migrate-db config.toml
  [======================================================================================================================================================================] 100/100MigrationReport { drop_cf: ["tx_block_info"], migrate_kv: {"tx_block_info__txn_hash_to_block_hash": 8537} }
(e2e-tests) kaiqichen@Mac:~/Documents/share/repo/smr-moonshot-mainnet/remote_env/Logs/rpc_0$ rpc-v9 migrate-db config.toml
Counting the number of entries to remove from prune_index...
Cleaning up prune index: [00:00:00] ████████████████████ 0/0 00:00:00                                                                                                             Counting the number of entries in block_to_transaction...
Migrating block_to_transaction: [00:00:00] ████████████████████ 8537/8537 00:00:00                                                                                                dropped:
- block_to_tx
migrated:
  block_to_tx -> block_to_tx_ordered: Migrated 8537 records, up to 239 block height
databases_checked:
- chain_store
- archive


#### smr

v7 -> v8 only cli profile and identity file migration

TO BE CONFIRMED: no change in smr_settings.toml and database in v8. 

v7 -> v9 smr_settings migration



v7 -> v9 database migration


(e2e-tests) kaiqichen@Mac:~/Documents/share/repo/smr-moonshot-mainnet/remote_env/Logs/node_0$ supra-v9 data migrate -p smr_settings.toml
Counting the number of entries in certified_block...
Migrating certified_block to certified_block_dehydrated: [00:00:00] ████████████████████ 69/69 00:00:00                                                                                       Counting the number of entries in uncommitted_block...
Preparing to clean up uncommitted_block: [00:00:00] ████████████████████ 74/74 00:00:00
Cleaning up uncommitted_block: [00:00:00] ████████████████████ 4/4 00:00:00                                                                                                                   Counting the number of entries in certified_block...
Counting the number of entries in certified_block_dehydrated...
Counting the number of entries in uncommitted_block...
Counting the number of entries in qc...
Verifying certified_block_dehydrated: [00:00:00] ████████████████████ 70/70 00:00:00                                                                                                          Counting the number of entries to remove from prune_index...
Cleaning up prune index: [00:00:00] ████████████████████ 70/70 00:00:00                                                                                                                       dropped:
- certified_block
migrated:
  certified_block -> certified_block_dehydrated: Migrated 70 records, up to 244 block height
databases_checked:
- chain_store
