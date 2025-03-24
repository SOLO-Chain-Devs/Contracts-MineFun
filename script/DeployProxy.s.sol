// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/upgradeable/MineFun.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployProxy is Script {
    function run() external {
        // Load the deployer's private key from ENV
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address uniswap_v2_router_ca = vm.envAddress("UNISWAP_V2_ROUTER_CA");
        address uniswap_v2_factory_ca = vm.envAddress("UNISWAP_V2_FACTORY_CA"); 
        address usdt_ca = vm.envAddress("USDT_CA");
        address team_wallet = vm.envAddress("TEAM_WALLET");
        // Start Broadcasting Transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the implementation contract
        MineFun implementation = new MineFun();
        console.log("MineFun implementation deployed at:", address(implementation));
        
        // Deploy ProxyAdmin (optional but recommended for managing upgrades)
        // Commented out for now - deployer will be admin
        // ProxyAdmin proxyAdmin = new ProxyAdmin();
        // console.log("ProxyAdmin deployed at:", address(proxyAdmin));
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            MineFun.initialize.selector,
            team_wallet,
            uniswap_v2_router_ca,
            uniswap_v2_factory_ca,
            usdt_ca
        );
        
        // Deploy TransparentUpgradeableProxy with deployer as admin
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            //address(proxyAdmin), // More secure way to deploy in production
            address(msg.sender), // Deployer is admin
            initData
        );
        console.log("MineFun proxy deployed at:", address(proxy));
        
        // For verification, create a reference to interact with the proxy
        MineFun mineFun = MineFun(address(proxy));
        console.log("MineFun initialized with team wallet:", mineFun.teamWallet());
        
        vm.stopBroadcast();
    }
}
