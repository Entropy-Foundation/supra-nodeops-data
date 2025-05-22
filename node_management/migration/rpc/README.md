
### Usage 

```sh
pip install .

# From v7 to v8
migrate-rpc-config -f config.toml -t config.toml -p 'v7->v8'

# From v8 to v9
migrate-rpc-config -f config.toml -t config.toml -p 'v8->v9'

# From v7 to v9 
migrate-rpc-config -f config.toml -t config.toml -p 'v7->v9'

```

#### v9 template
https://testnet-snapshot.supra.com/configs/config_v9.0.7.toml

#### v8 template
https://testnet-snapshot.supra.com/configs/config_v8.0.2.toml

#### v7 template
https://mainnet-data.supra.com/configs/config.toml