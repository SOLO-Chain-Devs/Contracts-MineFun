// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MemeTokenFactory.sol";

contract Deploy is Script {
    function run() external {
        // Load the deployer's private key from ENV
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start Broadcasting Transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the MemeTokenFactory contract
        MemeTokenFactory tokenFactory = new MemeTokenFactory();
        console.log("MemeTokenFactory deployed at:", address(tokenFactory));

        vm.stopBroadcast();
    }
}