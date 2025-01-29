// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MemeTokenFactory.sol";

contract MemeTokenFactoryTest is Test {
    MemeTokenFactory tokenFactory;

    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address user3 = vm.addr(3);
    address user4 = vm.addr(4);
    address user5 = vm.addr(5);
    address user6 = vm.addr(6);
    address user7 = vm.addr(7);
    address user8 = vm.addr(8);

    function setUp() public {
        string memory rpcUrl = vm.envString("RPC_URL");

        vm.createSelectFork(rpcUrl);
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
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

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

    function testBuyMemeToken() public {
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

    function testSellMemeToken() public {
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
        tokenFactory.sellMemeToken(memeTokenAddress, tokenQty);
        vm.stopPrank();
    }

    function testCostIncreasesExponentially() public {
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        uint tokenQty = 1000;
        uint previousCost = 0;
        uint totalETH;
        uint totalTokens;

        for (uint i = 1; i <= 200; i++) {
            uint cost = tokenFactory.getRequiredEthForPurchase(
                memeTokenAddress,
                tokenQty
            );
            totalETH+= cost;
            totalTokens+=tokenQty;

            //console.log("Iteration", i, "Cost:", cost);
            console.log("Total ETH value in USD",tokenFactory.getUSDValue(totalETH));
            require(cost > previousCost, "Cost did not increase");

            previousCost = cost;

            vm.startPrank(user1);
            vm.deal(user1, 100 ether);
            tokenFactory.buyMemeToken{value: cost}(memeTokenAddress, tokenQty);
            vm.stopPrank();
        }
        console.log("total",totalETH);
        console.log("totalTokens",totalTokens);
    }
}
