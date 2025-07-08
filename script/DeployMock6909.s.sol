// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/upgradeable/MineFun.sol";
import "../src/MockERC6909.sol";

contract RedeployImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        MockERC6909 mock = new MockERC6909();

        console.log("MockERC6909 deployed  at:", address(mock));

        vm.stopBroadcast();
    }
}
