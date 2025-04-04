# Prima Project

## Backend

### Test

Run automated tests
```bash
forge test
```

Run slither
```bash
slither .
```


### Deployment

Configure `.env` file
```yml
RPC_URL=127.0.0.1:8545 # Update for other testnet
PRIVATE_KEY = # Private key 
TOKEN_ADDRESS = # ERC 20 Prima token address
ETHERSCAN_API_KEY= # To verify on testnets (not used locally)
```

Set the env vars
```bash
source .env
```

### Local
Deploy the ERC 20 Token
```bash
forge script script/PrimaToken.s.sol:PrimaTokenScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast 
```

Deploy the Prima contract and children (Invoice NFT and Collateral)
```bash
forge script script/Prima.s.sol:PrimaScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast $TOKEN_ADDRESS --sig 'run(address)'
```

### Sepolia
Deploy the ERC 20 Token
```bash
forge script script/PrimaToken.s.sol:PrimaTokenScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --verify --broadcast 
```

Deploy the Prima contract and children (Invoice NFT and Collateral)
```bash
forge script script/Prima.s.sol:PrimaScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --verify --broadcast $TOKEN_ADDRESS --sig 'run(address)'
```

## Mint Tokens

Mint token for local
```bash
forge script script/PrimaTokenMintLocal.s.sol:PrimaTokenMintLocalScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast $TOKEN_ADDRESS --sig 'run(address)'
```

Mint token for sepolia
```bash
forge script script/PrimaTokenMintLocal.s.sol:PrimaTokenMintLocalScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast $TOKEN_ADDRESS --sig 'runSepolia(address)'
```

## Existing deployments

### Sepolia
- Token Address deployed at 0x148d3ee921B349c972d7E0DD5dab527C0502d640
- InvoiceNFT deployed at 0x12F300B5eFa94B784D57be9b09A6B5fF8f68eC2E
- Collateral deployed at 0xDC3a2cffBC8b16ea1208Fe6985370d2eDA964A23
- Prima deployed at 0x43792cC14690bcD18DAdFfc476799C6A3DDb18Ff
