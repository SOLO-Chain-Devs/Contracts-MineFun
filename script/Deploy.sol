// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MineFunImplementation.sol";
import {MineFunProxy} from "../src/MineFunProxy.sol"; 
import {Token} from "../src/Token.sol";

contract Deploy is Script {
    function run() external {
        // Load the deployer's private key from ENV
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start Broadcasting Transactions
        vm.startBroadcast(deployerPrivateKey);

        address teamWallet = 0xFE42ea5c89561901FdE0A0101671BC3190E4721e; // Replace with actual team wallet

        // ✅ Deploy the implementation contract
        MineFunImplementation implementation = new MineFunImplementation();

        // ✅ Deploy the proxy contract, pointing to the implementation
        MineFunProxy proxy = new MineFunProxy(address(implementation), "");

        // ✅ Cast the proxy address as MineFunImplementation
        MineFunImplementation tokenFactory = MineFunImplementation(address(proxy));

        // ✅ Initialize the proxy contract
        tokenFactory.initialize(teamWallet);

        console.log("MineFunImplementation deployed at:", address(implementation));
        console.log("MineFunProxy deployed at:", address(proxy));
        console.log("MineFun initialized with teamWallet:", teamWallet);

        vm.stopBroadcast();
    }
}  