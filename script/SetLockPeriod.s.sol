// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/MockDepinStaking.sol";

contract SetLockPeriod is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxy = vm.envAddress("DEPIN_PROXY");

        vm.startBroadcast(deployerPrivateKey);

        // Create a reference to the proxy
        DepinStaking depinStaking = DepinStaking(proxy);

        // Get current lock period
        uint256 currentLockPeriod = depinStaking.lockPeriod();
        console.log("Current lock period:", currentLockPeriod, "seconds");

        // Set new lock period to 10 minutes (600 seconds)
        uint256 newLockPeriod = 10 minutes; // 600 seconds
        depinStaking.setLockPeriod(newLockPeriod);

        // Verify the change
        uint256 updatedLockPeriod = depinStaking.lockPeriod();
        console.log("Updated lock period:", updatedLockPeriod, "seconds");
        console.log("Lock period set to 10 minutes successfully!");

        vm.stopBroadcast();
    }
}
