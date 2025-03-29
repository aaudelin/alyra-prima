# Prima Project

## Backend

### Deployment

Configure `.env` file
```yml
RPC_URL=127.0.0.1:8545 # Update for other testnet
PRIVATE_KEY = # Private key 
TOKEN_ADDRESS = # ERC 20 Prima token address
```

Set the env vars
```bash
source .env
```

Deploy the ERC 20 Token
```bash
forge script script/PrimaToken.s.sol:PrimaTokenScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Deploy the Prima contract and children (Invoice NFT and Collateral)
```bash
forge script script/Prima.s.sol:PrimaScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast $TOKEN_ADDRESS --sig 'run(address)'
```