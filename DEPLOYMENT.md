# MineFun Deployment Information

## Network: Solo Testnet (Chain ID: 8884571)

## Current Deployment (Latest)

### Proxy Contract (USE THIS ADDRESS)
- **Address**: `0x7ef926FAc26d9F7dBF635C48070108416a6303F2`
- **Type**: TransparentUpgradeableProxy
- **Admin**: `0x23c3b9b2897a3cca328062dab2cb9601dc6dd316` (Deployer wallet)
- **Status**: ✅ Active - Use this address for all interactions

### Current Implementation
- **Address**: `0xd32a511e46aEe703D2D4a7780Bdf8c2362AB24F8`
- **Contract**: MineFun
- **Deployed**: Latest upgrade
- **Status**: ✅ Active through proxy

## Previous Implementations

### Original Implementation
- **Address**: `0xbeab24392cd01597b2ff4a1328d6f754d4654f59`
- **Contract**: MineFun
- **Status**: ❌ Deprecated - Do not use directly

## Access Control

### Proxy Admin
- **Type**: EOA (Externally Owned Account)
- **Address**: `0x23c3b9b2897a3cca328062dab2cb9601dc6dd316`
- **Role**: Can upgrade proxy implementation
- **Note**: Same wallet that deployed the contracts

### Contract Owner
- **Address**: Set during initialization via `initialize()` function
- **Role**: Can call onlyOwner functions on the implementation

## Environment Variables

```bash
# Required for upgrades
PROXY_ADDRESS=0x7ef926FAc26d9F7dBF635C48070108416a6303F2
PRIVATE_KEY=<deployer_private_key>

# Other contract addresses
UNISWAP_V2_ROUTER_CA=<router_address>
UNISWAP_V2_FACTORY_CA=<factory_address>
USDT_CA=<usdt_address>
TEAM_WALLET=<team_wallet_address>
```

## Deployment History

### 2025-01-19 - Initial Proxy Deployment
- Deployed MineFun implementation: `0xbeab24392cd01597b2ff4a1328d6f754d4654f59`
- Deployed TransparentUpgradeableProxy: `0x7ef926FAc26d9F7dBF635C48070108416a6303F2`
- Set deployer as proxy admin (no ProxyAdmin contract)

### 2025-01-19 - Implementation Upgrade
- Deployed new MineFun implementation: `0xd32a511e46aEe703D2D4a7780Bdf8c2362AB24F8`
- Upgraded proxy to point to new implementation
- All data preserved in proxy

## Important Notes

⚠️ **ALWAYS USE THE PROXY ADDRESS** (`0x7ef926FAc26d9F7dBF635C48070108416a6303F2`)
- Frontend should interact with proxy address only
- Users should send transactions to proxy address
- Implementation addresses are for internal upgrade purposes only

✅ **Upgradeability**
- Contract is upgradeable through the proxy pattern
- Deployer wallet can upgrade implementation
- All state and data is stored in the proxy

🔐 **Security**
- Implementation includes `_disableInitializers()` to prevent direct initialization
- Proxy admin is the deployer wallet
- Consider transferring admin to a multisig for production

## Scripts

### Deploy New Implementation
```bash
forge script script/RedeployImplementation.s.sol --rpc-url $RPC_URL --broadcast
```

### Deploy Fresh Proxy (if needed)
```bash
forge script script/DeployProxy.s.sol --rpc-url $RPC_URL --broadcast
```

## Verification

To verify the current implementation address:
```bash
# Check implementation address stored in proxy
cast call 0x7ef926FAc26d9F7dBF635C48070108416a6303F2 "implementation()" --rpc-url $RPC_URL
```

To verify proxy admin:
```bash
# Check admin address of proxy
cast call 0x7ef926FAc26d9F7dBF635C48070108416a6303F2 "admin()" --rpc-url $RPC_URL
```