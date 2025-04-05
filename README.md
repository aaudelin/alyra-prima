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

## Frontend

Configure `.env.local` file
```yml
NEXT_PUBLIC_PROJECT_ID=
NEXT_PUBLIC_PRIMA_ADDRESS=
NEXT_PUBLIC_TOKEN_ADDRESS=
NEXT_PUBLIC_INVOICE_ADDRESS=
NEXT_PUBLIC_COLLATERAL_ADDRESS=
```

Install dependencies
```bash
npm i
```

Run project
```bash
npm run dev
```

## Existing deployments

### Sepolia
- Token Address deployed at 0x148d3ee921B349c972d7E0DD5dab527C0502d640
-  InvoiceNFT deployed at 0x144948DCa9f1F7f86c2f1efcaAD920cB7a86b9A1
-  Collateral deployed at 0x13C8Ae839b7C14794376C1aB9A19886d4996a09a
-  Prima deployed at 0x3f1B74647f34F6017CdB0C230BFE5157610B6b98
