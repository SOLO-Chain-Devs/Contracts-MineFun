// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/upgradeable/MineFun.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract RedeployImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_CA");
        address depinStakingAddress = vm.envAddress("DEPIN_STAKING_CA"); // Existing proxy contract

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation of MineFun
        MineFun newImplementation = new MineFun();
        console.log("New MineFun implementation deployed at:", address(newImplementation));

        // Upgrade the proxy directly (since deployer is admin, not ProxyAdmin contract)
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(proxyAddress);
        proxy.upgradeToAndCall(address(newImplementation), "");
        console.log("Proxy upgraded to new implementation at:", address(newImplementation));

        // set depin staking address
        MineFun(proxyAddress).setDepinStakingAddress(address(depinStakingAddress));
        console.log("Depin staking address set at:", address(depinStakingAddress));

        vm.stopBroadcast();
    }
}
