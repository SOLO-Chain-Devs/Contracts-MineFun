// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TokenFactory.sol";

contract TokenFactoryTest is Test {
    TokenFactory tokenFactory;

    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address user3 = vm.addr(3);
    address user4 = vm.addr(4);
    address user5 = vm.addr(5);
    address user6 = vm.addr(6);
    address user7 = vm.addr(7);
    address user8 = vm.addr(8);

    struct memeToken {
        string name;
        string symbol;
        string description;
        string tokenImageUrl;
        uint fundingRaised;
        address tokenAddress;
        address creatorAddress;
    }

    function setUp() public {
        vm.createSelectFork(
            "https://eth-mainnet.g.alchemy.com/v2/1ZZkhqTlUmgfWUP4KZrrrFGxnGRdSsS1"
        );
        tokenFactory = new TokenFactory();

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
        // Create a meme token
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        // Verify the token is listed
        TokenFactory.memeToken[] memory tokens = tokenFactory
            .getAllMemeTokens();
        assertEq(tokens.length, 1);
        assertEq(tokens[0].name, "Test Token");
        assertEq(tokens[0].tokenAddress, memeTokenAddress);
    } 

     function testCreateMemeTokenRevertsWithoutFee() public {
        vm.expectRevert(bytes("fee not paid for memetoken creation"));
        tokenFactory.createMemeToken{value: 0.00001 ether}(
            "Test Token",
            "TEST",
            "img://test.png",
            "This is a test token"
        );
    } 

    function testBuyMemeToken() public {
        // Create a meme token
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        // Get required ETH
        uint tokenQty = 100;
        vm.startPrank(user1, user1);
        uint requiredEth = tokenFactory.getRequiredEthForPurchase(
            memeTokenAddress,
            tokenQty
        );
        // Buy tokens
        tokenFactory.buyMemeToken{value: requiredEth}(
            memeTokenAddress,
            tokenQty
        );
        vm.stopPrank();

        // Access the meme token struct from the mapping
        (
            string memory name,
            string memory symbol,
            ,
            ,
            uint fundingRaised,
            ,
            address creatorAddress
        ) = tokenFactory.addressToMemeTokenMapping(memeTokenAddress);

        // Verify funding raised
        assertEq(fundingRaised, requiredEth);

        // Verify user's balance
        Token token = Token(memeTokenAddress);
        assertEq(token.balanceOf(user1), tokenQty * 10 ** 18);

        // Additional field checks
        assertEq(name, "Test Token");
        assertEq(symbol, "TEST");
        assertEq(creatorAddress, address(this));
    }

    function testLargeBuyMemeToken() public {
        // Create a meme token
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        // User tries to buy a large number of tokens
        uint tokenQty = 100000; // Large quantity
        vm.startPrank(user1, user1);
        uint requiredEth = tokenFactory.getRequiredEthForPurchase(
            memeTokenAddress,
            tokenQty
        );

        // Log required ETH for debugging
        console.log("Required ETH for large purchase:", requiredEth);

        // Attempt to buy tokens with sufficient ETH
        vm.deal(user1, 500 ether); // Ensure user1 has enough ETH
        tokenFactory.buyMemeToken{value: requiredEth}(
            memeTokenAddress,
            tokenQty
        );
        vm.stopPrank();

        // Verify user's balance
        Token token = Token(memeTokenAddress);
        assertEq(token.balanceOf(user1), tokenQty * 10 ** 18);
    }

    function testBuyMemeTokenRevertsOnInsufficientETH() public {
        // Create a meme token
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        // Attempt to buy tokens with insufficient ETH
        uint tokenQty = 100;
        vm.expectRevert(bytes("Incorrect value of ETH sent"));
        tokenFactory.buyMemeToken{value: 0.001 ether}(
            memeTokenAddress,
            tokenQty
        );
    }

    function testFundingGoalTriggersLiquidity() public {
        // Create a meme token
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        // Reach the funding goal
        tokenFactory.buyMemeToken{value: 10 ether}(memeTokenAddress, 1000);

        // Verify liquidity pool is created
        // Check console logs for pool and liquidity details
    }

    function testBuyAndSellTokensWithBondingCurve() public {
    // Create a meme token
    address memeTokenAddress = tokenFactory.createMemeToken{
        value: 0.0001 ether
    }("Test Token", "TEST", "img://test.png", "This is a test token");

    Token token = Token(memeTokenAddress);

    uint tokenQty = 100; // Fixed token quantity for all buyers (in token units)

    // Track the ETH cost for each user
    uint previousEthCost = 0;

    // Simulate 7 users buying the same amount of tokens
    address[] memory users = new address[](7);
    users[0] = user1;
    users[1] = user2;
    users[2] = user3;
    users[3] = user4;
    users[4] = user5;
    users[5] = user6;
    users[6] = user7;

    for (uint i = 0; i < 7; i++) {
        vm.startPrank(users[i]);
        uint ethCost = tokenFactory.getRequiredEthForPurchase(
            memeTokenAddress,
            tokenQty
        );

        console.log(
            "User ",
            i + 1,
            " required ETH for purchase: ",
            ethCost
        );

        // Ensure ETH cost increases due to bonding curve
        require(ethCost > previousEthCost, "ETH cost did not increase");

        // Fund user and buy tokens
        vm.deal(users[i], 100 ether);
        tokenFactory.buyMemeToken{value: ethCost}(memeTokenAddress, tokenQty);

        // Verify user's token balance
        assertEq(token.balanceOf(users[i]), tokenQty * 10 ** 18);

        previousEthCost = ethCost;
        vm.stopPrank();
    }

    // Simulate user8 buying tokens
    vm.startPrank(user8);
    uint ethCostUser8 = tokenFactory.getRequiredEthForPurchase(
        memeTokenAddress,
        tokenQty
    );

    console.log("User 8 required ETH for purchase: ", ethCostUser8);

    // Fund user8 and buy tokens
    vm.deal(user8, 100 ether);
    tokenFactory.buyMemeToken{value: ethCostUser8}(memeTokenAddress, tokenQty);

    // Verify user8's token balance
    assertEq(token.balanceOf(user8), tokenQty * 10 ** 18);

    // User8 sells back all tokens
    uint sellerInitialEthBalance = user8.balance;
    token.approve(address(tokenFactory), tokenQty * 10 ** 18); // Approve the factory to transfer tokens
    tokenFactory.sellMemeToken(memeTokenAddress, tokenQty);

    // Check user8's ETH balance after selling
    uint sellerFinalEthBalance = user8.balance;
    uint receivedRevenue = sellerFinalEthBalance - sellerInitialEthBalance;

    console.log("User 8 ETH received after selling: ", receivedRevenue);

    // Verify user8 receives approximately the same ETH back
    assertApproxEqAbs(receivedRevenue, ethCostUser8, 1e14); // Allow small deviation

    vm.stopPrank();
}

   
}
