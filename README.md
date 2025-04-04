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
- InvoiceNFT deployed at 0x79Dd05992a63d7D143B5a9AEDD15B16aC97A5BC2
- Collateral deployed at 0x41ac467E377aee2eaA643F1a31CDb01A9E15A89F
- Prima deployed at 0xdd4c20bEf5Ab8ca9af4031Fd858b8162ed1e572d
