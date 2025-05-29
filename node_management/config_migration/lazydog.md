alias rpc-v8=~/Documents/share/repo/smr-moonshot-testnet/target/devopt/rpc_node
alias rpc-v9=~/Documents/share/repo/smr-moonshot/target/release/rpc_node
alias supra-v8="~/Documents/share/repo/smr-moonshot-testnet/target/devopt/supra"
alias supra-v9="~/Documents/share/repo/smr-moonshot/target/release/supra"
export NODE_OPERATOR_KEY_PASSWORD="88888888"


# SMR
supra-v8 migrate --network localnet


cp validator_identity.pem node_identity.pem
supra-v9 profile migrate
sed -i '' 's/is_testnet = true/is_testnet = false/' smr_settings.toml
migrate-config smr -p v7-v9 -f smr_settings.toml -t smr_settings.toml


lsof -n -P -iTCP:26002-26006 -sTCP:LISTEN

supra-v9 data migrate -p smr_settings.toml


supra-v9 node smr run


### RPC
sed -i '' 's/is_testnet = true/is_testnet = false/' config.toml
migrate-config rpc -p v7-v9  -f config.toml -t config.toml



rpc-v8 migrate-db config.toml

rpc-v9 migrate-db config.toml
rpc-v9 start &