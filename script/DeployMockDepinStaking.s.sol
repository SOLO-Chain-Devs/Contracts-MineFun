// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/upgradeable/MineFun.sol";
import "../src/MockERC6909.sol";
import "../src/MockDepinStaking.sol";

contract RedeployImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        MockERC6909 mock = new MockERC6909();
        mock.mint(msg.sender, 1, 1);

        DepinStaking stakingContract = new DepinStaking(address(mock));

        mock.approve(address(stakingContract), 1, 1);
        stakingContract.stake(1, 1);

        bool isStaked = stakingContract.isStaking(msg.sender);
        console.log("Is User Staking?: ",isStaked);

        console.log("MockERC6909 deployed  at:", address(mock));
        console.log("DepinStaking deployed  at:", address(stakingContract));

        vm.stopBroadcast();
    }
}
