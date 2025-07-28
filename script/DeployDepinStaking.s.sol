// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/upgradeable/MineFun.sol";
import "../src/ERC6909.sol";
import "../src/MockDepinStaking.sol";

contract RedeployImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);


        DepinStaking stakingContract = new DepinStaking();

      
        console.log("DepinStaking deployed  at:", address(stakingContract));

        vm.stopBroadcast();
    }
}
