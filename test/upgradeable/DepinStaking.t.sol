// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {DepinStaking} from "../../src/MockDepinStaking.sol";
import {MockERC6909} from "../../src/MockERC6909.sol";

contract MockDepinStakingTest is Test {
    DepinStaking public depinStaking;
    MockERC6909 public mockToken1;
    MockERC6909 public mockToken2;

    address deployer;
    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address user3 = vm.addr(3);

    function setUp() public {
        deployer = msg.sender;
        string memory rpcUrl = vm.envString("RPC_URL");

        vm.createSelectFork(rpcUrl);
        vm.startPrank(deployer);

        // Deploy contracts
        depinStaking = new DepinStaking();
        mockToken1 = new MockERC6909();
        mockToken2 = new MockERC6909();

        vm.stopPrank();

        // Fund users with tokens
        vm.startPrank(deployer);
        mockToken1.mint(user1, 1, 100); // user1 gets 100 of tokenId 1
        mockToken1.mint(user2, 1, 50);  // user2 gets 50 of tokenId 1
        mockToken1.mint(user1, 2, 200); // user1 gets 200 of tokenId 2
        mockToken2.mint(user1, 1, 75);  // user1 gets 75 of tokenId 1 from token2
        mockToken2.mint(user3, 1, 25);  // user3 gets 25 of tokenId 1 from token2
        vm.stopPrank();
    }

    function test_StakeTokens() public {
        vm.startPrank(user1);
        
        // Approve tokens for staking
        mockToken1.approve(address(depinStaking), 1, 50);
        
        // Stake tokens
        depinStaking.stake(address(mockToken1), 1, 50);
        
        // Verify staked balance
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 50, "Staked balance should be 50");
        assertTrue(depinStaking.isStaking(user1), "User should be staking");
        
        // Verify token transfer
        assertEq(mockToken1.balanceOf(user1, 1), 50, "User should have 50 tokens remaining");
        assertEq(mockToken1.balanceOf(address(depinStaking), 1), 50, "Staking contract should have 50 tokens");
        
        vm.stopPrank();
    }

    function test_StakeMultipleTokenIds() public {
        vm.startPrank(user1);
        
        // Approve tokens for staking
        mockToken1.approve(address(depinStaking), 1, 30);
        mockToken1.approve(address(depinStaking), 2, 100);
        
        // Stake different token IDs
        depinStaking.stake(address(mockToken1), 1, 30);
        depinStaking.stake(address(mockToken1), 2, 100);
        
        // Verify staked balances
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 30, "TokenId 1 staked balance should be 30");
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 2), 100, "TokenId 2 staked balance should be 100");
        assertTrue(depinStaking.isStaking(user1), "User should be staking");
        
        vm.stopPrank();
    }

    function test_StakeMultipleTokens() public {
        vm.startPrank(user1);
        
        // Approve tokens for staking
        mockToken1.approve(address(depinStaking), 1, 40);
        mockToken2.approve(address(depinStaking), 1, 50);
        
        // Stake different tokens
        depinStaking.stake(address(mockToken1), 1, 40);
        depinStaking.stake(address(mockToken2), 1, 50);
        
        // Verify staked balances
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 40, "Token1 staked balance should be 40");
        assertEq(depinStaking.stakedOf(user1, address(mockToken2), 1), 50, "Token2 staked balance should be 50");
        assertTrue(depinStaking.isStaking(user1), "User should be staking");
        
        vm.stopPrank();
    }

    function test_UnstakeTokens() public {
        vm.startPrank(user1);
        
        // Approve and stake tokens
        mockToken1.approve(address(depinStaking), 1, 50);
        depinStaking.stake(address(mockToken1), 1, 50);
        
        // Unstake some tokens
        depinStaking.unstake(address(mockToken1), 1, 20);
        
        // Verify remaining staked balance
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 30, "Remaining staked balance should be 30");
        assertTrue(depinStaking.isStaking(user1), "User should still be staking");
        
        // Verify token transfer back
        assertEq(mockToken1.balanceOf(user1, 1), 70, "User should have 70 tokens (50 original - 50 staked + 20 unstaked)");
        assertEq(mockToken1.balanceOf(address(depinStaking), 1), 30, "Staking contract should have 30 tokens");
        
        vm.stopPrank();
    }

    function test_UnstakeAllTokens() public {
        vm.startPrank(user1);
        
        // Approve and stake tokens
        mockToken1.approve(address(depinStaking), 1, 50);
        depinStaking.stake(address(mockToken1), 1, 50);
        
        // Unstake all tokens
        depinStaking.unstake(address(mockToken1), 1, 50);
        
        // Verify no staked balance
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 0, "Staked balance should be 0");
        assertFalse(depinStaking.isStaking(user1), "User should not be staking");
        
        // Verify all tokens returned
        assertEq(mockToken1.balanceOf(user1, 1), 100, "User should have all tokens back");
        assertEq(mockToken1.balanceOf(address(depinStaking), 1), 0, "Staking contract should have no tokens");
        
        vm.stopPrank();
    }

    function test_StakeZeroAmount() public {
        vm.startPrank(user1);
        
        mockToken1.approve(address(depinStaking), 1, 50);
        
        vm.expectRevert("Cannot stake 0");
        depinStaking.stake(address(mockToken1), 1, 0);
        
        vm.stopPrank();
    }

    function test_UnstakeZeroAmount() public {
        vm.startPrank(user1);
        
        mockToken1.approve(address(depinStaking), 1, 50);
        depinStaking.stake(address(mockToken1), 1, 50);
        
        vm.expectRevert("Cannot unstake 0");
        depinStaking.unstake(address(mockToken1), 1, 0);
        
        vm.stopPrank();
    }

    function test_UnstakeMoreThanStaked() public {
        vm.startPrank(user1);
        
        mockToken1.approve(address(depinStaking), 1, 50);
        depinStaking.stake(address(mockToken1), 1, 50);
        
        vm.expectRevert("Not enough staked");
        depinStaking.unstake(address(mockToken1), 1, 60);
        
        vm.stopPrank();
    }

    function test_UnstakeWithoutStaking() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Not enough staked");
        depinStaking.unstake(address(mockToken1), 1, 10);
        
        vm.stopPrank();
    }

    function test_TransferFailure() public {
        vm.startPrank(user1);
        
        // Don't approve tokens
        vm.expectRevert();

        depinStaking.stake(address(mockToken1), 1, 50);
        
        vm.stopPrank();
    }

    function test_MultipleUsersStaking() public {
        // User1 stakes
        vm.startPrank(user1);
        mockToken1.approve(address(depinStaking), 1, 50);
        depinStaking.stake(address(mockToken1), 1, 50);
        vm.stopPrank();
        
        // User2 stakes
        vm.startPrank(user2);
        mockToken1.approve(address(depinStaking), 1, 30);
        depinStaking.stake(address(mockToken1), 1, 30);
        vm.stopPrank();
        
        // User3 stakes different token
        vm.startPrank(user3);
        mockToken2.approve(address(depinStaking), 1, 25);
        depinStaking.stake(address(mockToken2), 1, 25);
        vm.stopPrank();
        
        // Verify all users are staking
        assertTrue(depinStaking.isStaking(user1), "User1 should be staking");
        assertTrue(depinStaking.isStaking(user2), "User2 should be staking");
        assertTrue(depinStaking.isStaking(user3), "User3 should be staking");
        
        // Verify individual balances
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 50, "User1 should have 50 staked");
        assertEq(depinStaking.stakedOf(user2, address(mockToken1), 1), 30, "User2 should have 30 staked");
        assertEq(depinStaking.stakedOf(user3, address(mockToken2), 1), 25, "User3 should have 25 staked");
    }

    function test_StakeAndUnstakeMultipleTimes() public {
        vm.startPrank(user1);
        
        mockToken1.approve(address(depinStaking), 1, 100);
        
        // First stake
        depinStaking.stake(address(mockToken1), 1, 30);
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 30, "First stake should be 30");
        
        // Second stake
        depinStaking.stake(address(mockToken1), 1, 20);
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 50, "Total staked should be 50");
        
        // First unstake
        depinStaking.unstake(address(mockToken1), 1, 15);
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 35, "After first unstake should be 35");
        
        // Second unstake
        depinStaking.unstake(address(mockToken1), 1, 25);
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 10, "After second unstake should be 10");
        
        // Final unstake
        depinStaking.unstake(address(mockToken1), 1, 10);
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 0, "Final balance should be 0");
        assertFalse(depinStaking.isStaking(user1), "User should not be staking");
        
        vm.stopPrank();
    }

    function test_StakeDifferentTokenIds() public {
        vm.startPrank(user1);
        
        mockToken1.approve(address(depinStaking), 1, 50);
        mockToken1.approve(address(depinStaking), 2, 100);
        
        // Stake different token IDs
        depinStaking.stake(address(mockToken1), 1, 50);
        depinStaking.stake(address(mockToken1), 2, 100);
        
        // Verify balances are tracked separately
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 50, "TokenId 1 should be 50");
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 2), 100, "TokenId 2 should be 100");
        
        // Unstake from one tokenId
        depinStaking.unstake(address(mockToken1), 1, 30);
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 1), 20, "TokenId 1 should be 20");
        assertEq(depinStaking.stakedOf(user1, address(mockToken1), 2), 100, "TokenId 2 should still be 100");
        
        vm.stopPrank();
    }

    function test_IsStakingFunction() public {
        // Initially no one is staking
        assertFalse(depinStaking.isStaking(user1), "User1 should not be staking initially");
        assertFalse(depinStaking.isStaking(user2), "User2 should not be staking initially");
        
        // User1 stakes
        vm.startPrank(user1);
        mockToken1.approve(address(depinStaking), 1, 50);
        depinStaking.stake(address(mockToken1), 1, 50);
        vm.stopPrank();
        
        assertTrue(depinStaking.isStaking(user1), "User1 should be staking");
        assertFalse(depinStaking.isStaking(user2), "User2 should not be staking");
        
        // User1 unstakes everything
        vm.startPrank(user1);
        depinStaking.unstake(address(mockToken1), 1, 50);
        vm.stopPrank();
        
        assertFalse(depinStaking.isStaking(user1), "User1 should not be staking after unstaking all");
    }
} 