# MineFun Deployment Information

## Network: Solo Testnet (Chain ID: 8884571)

## Current Deployment (Latest)

### Proxy Contract (USE THIS ADDRESS)
- **Address**: `0xeB9c13a16846c943F443Bfe7721f08351A5Db8a6`
- **Type**: TransparentUpgradeableProxy
- **Admin**: `0x3b7966d16b59a5548709ef3c5877ee1862e820f4` (ProxyAdmin contract)
- **Admin Owner**: `0x23c3b9b2897A3cca328062DAB2CB9601Dc6dD316` (Deployer wallet)
- **Status**: ✅ Active - Use this address for all interactions

### Current Implementation
- **Address**: `0xeB9c13a16846c943F443Bfe7721f08351A5Db8a6`
- **Contract**: MineFun
- **Deployed**: 2025-06-12 23:08:07 UTC
- **Status**: ✅ Active through proxy

## Previous Implementations

### Original Implementation
NOTE: We accessed this directly. This was a mistake.
- **Address**: `0xeB9c13a16846c943F443Bfe7721f08351A5Db8a6`
- **Contract**: MineFun
- **Status**: ❌ Deprecated - Do not use directly

## Access Control

### Proxy Admin
- **Type**: ProxyAdmin Contract
- **Address**: `0xeB9c13a16846c943F443Bfe7721f08351A5Db8a6`
- **Owner**: `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38`
- **Role**: Can upgrade proxy implementation via ProxyAdmin contract
- **Note**: ⚠️ Uses ProxyAdmin pattern, not direct EOA admin

### Contract Owner
- **Address**: Set during initialization via `initialize()` function
- **Role**: Can call onlyOwner functions on the implementation

## Environment Variables

```bash
# Required for upgrades
PROXY_ADDRESS=0x63029F4622c80053795db373010C00cDbB27ED18
PRIVATE_KEY=<deployer_private_key>

# Other contract addresses
UNISWAP_V2_ROUTER_CA=<router_address>
UNISWAP_V2_FACTORY_CA=<factory_address>
USDT_CA=<usdt_address>
TEAM_WALLET=<team_wallet_address>
```

## Deployment History

### 2025-06-12 23:08:07 UTC - Automated Implementation Upgrade
- Deployed new MineFun implementation: `0xeB9c13a16846c943F443Bfe7721f08351A5Db8a6`
- Upgraded proxy to point to new implementation
- Commit: `93808bbf49d55ca546fcccf621de2d2eba6df06b`
- All data preserved in proxy

### 13-06-2025 Clean Deployment with Updated Script (CURRENT)
- Deployed MineFun implementation: `0xf7dbC29DB695d0f809f8738e964A669b914c698E`
- Deployed TransparentUpgradeableProxy: `0x63029F4622c80053795db373010C00cDbB27ED18`
- Deployed ProxyAdmin: `0x3b7966d16b59a5548709ef3c5877ee1862e820f4`
- ProxyAdmin owner: `0x23c3b9b2897A3cca328062DAB2CB9601Dc6dD316` (Deployer wallet)
- Clean setup using `deployerAddress` instead of `msg.sender` to avoid foundry default caller

### Previous Deployments (Deprecated)
- Old proxy: `0x7ef926FAc26d9F7dBF635C48070108416a6303F2`
- Multiple implementation upgrades
- Admin confusion resolved with clean deployment

## Important Notes

⚠️ **ALWAYS USE THE PROXY ADDRESS** (`0x63029F4622c80053795db373010C00cDbB27ED18`)
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

## Automated Deployments (GitHub Actions)

### Setup GitHub Secrets
Add these secrets in GitHub repo → Settings → Secrets and Variables → Actions:
- `DEPLOYER_PK` - Your deployer private key
- `RPC_URL` - Solo testnet RPC endpoint
- `PROXY_ADDRESS` - `0x63029F4622c80053795db373010C00cDbB27ED18`

### Deployment Workflow
1. **Create deployment branch**: `git checkout -b deploy/redeploy-implementation`
2. **Make contract changes** and commit
3. **Push to trigger deployment**: `git push origin deploy/redeploy-implementation`
4. **GitHub Actions will automatically**:
   - Deploy new implementation
   - Upgrade proxy
   - Update this file with new addresses
   - Commit changes back to the branch

### Manual Deployment
```bash
forge script script/RedeployImplementation.s.sol --rpc-url $RPC_URL --broadcast
```

## Verification
```bash
# Check current implementation (via storage)
cast storage $PROXY_ADDRESS 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url $RPC_URL

# Check proxy admin (via storage)
cast storage $PROXY_ADDRESS 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103 --rpc-url $RPC_URL
```
