// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MemeTokenFactory.sol";
import {Token} from "../src/Token.sol";

contract MemeTokenFactoryTest is Test {
    MemeTokenFactory tokenFactory;

    address deployer;

    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address user3 = vm.addr(3);
    address user4 = vm.addr(4);
    address user5 = vm.addr(5);
    address user6 = vm.addr(6);
    address user7 = vm.addr(7);
    address user8 = vm.addr(8);

    function setUp() public {
        deployer = msg.sender;
        string memory rpcUrl = vm.envString("RPC_URL");

        vm.createSelectFork(rpcUrl);
        vm.prank(deployer);
        tokenFactory = new MemeTokenFactory();

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
        vm.deal(user5, 100 ether);
        vm.deal(user6, 100 ether);
        vm.deal(user7, 100 ether);
        vm.deal(user8, 100 ether);
    }

    function testCreateMemeToken() public {
        vm.prank(user1);
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        address token = Token(memeTokenAddress).owner();
        console.log("Owner: ", token);
        console.log("User1:", user1);
        console.log("Factory: ", address(tokenFactory));
        

        MemeTokenFactory.MemeToken[] memory tokens = tokenFactory
            .getAllMemeTokens();
        assertEq(tokens.length, 1);
        assertEq(tokens[0].name, "Test Token");
        assertEq(tokens[0].tokenAddress, memeTokenAddress);
    }

    function testCreateMemeTokenRevertsWithoutFee() public {
        vm.expectRevert(bytes("Insufficient creation fee"));
        tokenFactory.createMemeToken{value: 0.00001 ether}(
            "Test Token",
            "TEST",
            "img://test.png",
            "This is a test token"
        );
    }

    function testMineTokens() public {
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        uint tokenQty = 100;
        vm.startPrank(user1);
        uint requiredEth = tokenFactory.getRequiredEthForPurchase(
            memeTokenAddress,
            tokenQty
        );
        tokenFactory.buyMemeToken{value: requiredEth}(
            memeTokenAddress,
            tokenQty
        );
        vm.stopPrank();
    }

    function testCostIncreasesExponentially() public {
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        uint tokenQty = 8_000_000 ether;
        uint previousCost = 0;
        uint totalETH;
        uint totalTokens;

        for (uint i = 1; i <= 100; i++) {
            uint cost = tokenFactory.getRequiredEthForPurchase(
                memeTokenAddress,
                tokenQty
            );
            totalETH += cost;
            totalTokens += tokenQty;

            console.log(
                "Total ETH value in USD",
                tokenFactory.getUSDValue(totalETH)
            );
            require(cost > previousCost, "Cost did not increase");

            previousCost = cost;

            vm.startPrank(user1);
            vm.deal(user1, 100 ether);
            tokenFactory.buyMemeToken{value: cost}(memeTokenAddress, tokenQty);
            vm.stopPrank();
        }

        /*  uint newcost = tokenFactory.getRequiredEthForPurchase(
                memeTokenAddress,
                1000
            );
             vm.startPrank(user1);
            vm.deal(user1, 100 ether);
            tokenFactory.buyMemeToken{value: newcost}(memeTokenAddress, tokenQty);
            vm.stopPrank(); */

        console.log("total ETH", totalETH);
        console.log("totalTokens", totalTokens);
    }
    function testBuyMemeTokenRevertsWhenSupplyExceeds() public {
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        uint tokenQty = 799_999_999 ether; // Buy just under 800M tokens
        vm.startPrank(user1);
        uint requiredEth = tokenFactory.getRequiredEthForPurchase(
            memeTokenAddress,
            tokenQty
        );
        tokenFactory.buyMemeToken{value: requiredEth}(
            memeTokenAddress,
            tokenQty
        );
        vm.stopPrank();

        // Attempt to exceed the supply limit
        vm.startPrank(user2);
        uint requiredEth2 = tokenFactory.getRequiredEthForPurchase(
            memeTokenAddress,
            tokenQty
        );
        vm.expectRevert(bytes("Not enough tokens left"));
        tokenFactory.buyMemeToken{value: requiredEth2}(memeTokenAddress, 100 ether); // Try buying 10 extra tokens
        vm.stopPrank();
    }

    function test_Provides_Liquidity() public {
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        uint totalTokensToBuy = 800_000_000 ether;
        uint totalEthSpent;
        uint tokensBought;
        uint tokenBatch = 8_000_000 ether; // Buy in chunks of 1% of total

        vm.startPrank(user1);

        while (tokensBought < totalTokensToBuy) {
            uint requiredEth = tokenFactory.getRequiredEthForPurchase(
                memeTokenAddress,
                tokenBatch
            );

            // Ensure last batch doesn't exceed total supply
            if (tokensBought + tokenBatch > totalTokensToBuy) {
                tokenBatch = totalTokensToBuy - tokensBought;
            }

            tokenFactory.buyMemeToken{value: requiredEth}(
                memeTokenAddress,
                tokenBatch
            );

            tokensBought += tokenBatch;
            totalEthSpent += requiredEth;
        }

        vm.stopPrank();

        (
            string memory name,
            string memory symbol,
            string memory description,
            string memory tokenImageUrl,
            uint fundingRaised,
            uint tokensBoughtFinal,
            address tokenAddress,
            address creatorAddress,
            bool bonded
        ) = tokenFactory.addressToMemeTokenMapping(memeTokenAddress);

        console.log("Token Name:", name);
        console.log("Token Symbol:", symbol);
        console.log("Description:", description);
        console.log("Token Image URL:", tokenImageUrl);
        console.log("Funding Raised:", fundingRaised);
        console.log("Tokens Bought:", tokensBoughtFinal);
        console.log("Token Address:", tokenAddress);
        console.log("Creator Address:", creatorAddress);
        console.log("Bonded:", bonded);
    }
}
