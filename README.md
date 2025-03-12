# MineFun Platform

## Overview

MineFun is a decentralized platform that enables users to create, mine, and trade tokenized assets with automated liquidity pool creation. The platform implements a bonding curve mechanism where tokens are mined through ETH contributions, with automated liquidity provision once funding goals are met.

## Key Features

- **Token Creation**: Users can create custom ERC20 tokens with minimal setup
- **Mining Mechanism**: Contributors can "mine" tokens by sending ETH
- **Automated Liquidity**: Once funding goals are reached, liquidity pools are automatically created
- **Bonding Period**: Each token has a configurable bonding period (1 minute to 7 days)
- **Refund System**: Contributors can get refunds if bonding goals aren't met
- **Upgradeable Architecture**: Contract uses UUPS proxy pattern for future upgrades

## Technical Architecture

The platform is built with a modular contract structure:

```
src/
├── Token.sol                 # ERC20 token implementation
└── upgradeable/              # Core platform contracts
    ├── IMineFun.sol          # Interface definitions
    ├── MineFunAdmin.sol      # Admin functionality
    ├── MineFunCore.sol       # Core business logic
    ├── MineFun.sol           # Main implementation contract
    ├── MineFunStorage.sol    # Storage variables and structs
    └── MineFunView.sol       # View functions
```

### Token Contract

The `Token.sol` contract implements a standard ERC20 token with additional features:
- Transfer restriction until bonding is complete
- Minting/burning capabilities controlled by owner
- Launch functionality to enable transfers

### Core Platform

The platform uses an upgradeable contract architecture with distinct responsibilities:

- **MineFunStorage**: Defines state variables and constants
- **MineFunAdmin**: Provides administrative functions
- **MineFunCore**: Implements core business logic
- **MineFunView**: Offers view functions for data retrieval
- **MineFun**: Main contract that inherits all functionality

## How It Works

1. **Token Creation**: Users create a new token by providing name, symbol, description, image URL, and bonding time
2. **Mining Phase**: Users can mine tokens by sending ETH (0.0002 ETH per mine)
3. **Bonding Mechanism**: 
   - 50% of contributions go to the team wallet
   - 50% is reserved for liquidity provision
   - Once 1 ETH is raised for liquidity, bonding is complete
4. **Liquidity Provision**: When bonding completes, a Uniswap V2 liquidity pool is automatically created
5. **Token Launch**: After successful bonding, token transfers are enabled

## Token Economics

- **Initial Supply**: 500M tokens (50% of max supply)
- **Maximum Supply**: 1B tokens
- **Tokens Per Mine**: 50,000 tokens
- **Maximum Per Wallet**: 10M tokens
- **Mining Price**: 0.0002 ETH per mine
- **Creation Fee**: 0.0001 ETH

## Environment Setup

Create a `.env` file based on the provided `.env.example`:

```
PRIVATE_KEY=                                            # Your wallet private key
RPC_URL=https://solo-testnet.rpc.caldera.xyz/http      # Default RPC URL for Caldera Solo testnet
SOLO_TESTNET_BLOCKSCOUT_API_URL=https://solo-testnet.explorer.caldera.xyz/api
SOLO_TESTNET_RPC_URL=https://solo-testnet.rpc.caldera.xyz/http

# Pre-configured addresses
TEAM_WALLET
UNISWAP_V2_ROUTER_CA
UNISWAP_V2_FACTORY_CA
USDT_CA
```

## Deployment

The project uses Foundry for deployment with the following scripts:

```
script/
├── DeployProxy.s.sol         # Deploys the upgradeable proxy system
├── Imports-factory.s.sol     # Uniswap factory imports
├── Imports.router.s.sol      # Uniswap router imports
└── UniswapDeployer.s.sol     # Deploys Uniswap contracts for testing
```

### Deployment Steps

1. Install dependencies:
   ```
   forge install
   ```

2. Create your `.env` file from the example:
   ```
   cp .env.example .env
   ```

3. Add your private key to the `.env` file

4. Deploy to Caldera Solo testnet:
   ```
   forge script script/DeployProxy.s.sol --rpc-url $SOLO_TESTNET_RPC_URL --broadcast
   ```

5. For verification on Blockscout (optional):
   ```
   forge script script/DeployProxy.s.sol --rpc-url $SOLO_TESTNET_RPC_URL --broadcast --verify --verifier blockscout --verifier-url $SOLO_TESTNET_BLOCKSCOUT_API_URL --chain-id 8884571
   ```

## Interacting with the Platform

### Creating a Mined Token

To create a new token, call the `createMinedToken` function with the following parameters:
- `name`: Token name
- `symbol`: Token symbol
- `imageUrl`: URL to token image
- `description`: Token description
- `bondingTime`: Duration of bonding period in seconds (between 1 minute and 7 days)

The creation requires a fee of 0.0001 ETH.

### Mining Tokens

To mine tokens, call the `mineToken` function with:
- `minedTokenAddress`: Address of the token to mine

Mining requires sending 0.0002 ETH per mine operation and is limited to 10M tokens per wallet.

### Refunding Contributions

If a token fails to reach its bonding goal by the deadline, contributors can get refunds by calling:
- `refundContributors(minedTokenAddress)`

## Security Considerations

- The contract uses CREATE2 for deterministic token addresses
- Bonding mechanism protects contributors with refund options
- Transfer restrictions prevent trading before liquidity is established
- Upgradeable design allows for future improvements

## Testing

Run tests with Foundry:

```
forge test
```

## Dependencies

- OpenZeppelin Contracts (Access Control, ERC20, Proxy)
- Uniswap V2 (Router, Factory interfaces)
- Foundry (Development and testing)

## Network Information

The project is configured to deploy on Caldera Solo testnet by default:
- RPC URL: https://solo-testnet.rpc.caldera.xyz/http
- Explorer API: https://solo-testnet.explorer.caldera.xyz/api
- Chain ID: 8884571

