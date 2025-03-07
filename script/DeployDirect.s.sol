// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/upgradeable/MineFun.sol";
import {Token} from "../src/Token.sol";

contract Deploy is Script {
    function run() external {
        // Load the deployer's private key from ENV
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start Broadcasting Transactions
        vm.startBroadcast(deployerPrivateKey);
        
        //address teamWallet = vm.envAddress("TEAM_WALLET");        
        address teamWallet = msg.sender;

        // Deploy the MineFun contract directly
        MineFun tokenFactory = new MineFun();
        
        // Initialize the contract
        tokenFactory.initialize(teamWallet);
        
        console.log("MineFun deployed at:", address(tokenFactory));
        console.log("MineFun initialized with teamWallet:", teamWallet);
        
        vm.stopBroadcast();
    }
}
