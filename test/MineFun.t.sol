// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TokenFactory.sol";

contract TokenFactoryTest is Test {
    TokenFactory tokenFactory;

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
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/1ZZkhqTlUmgfWUP4KZrrrFGxnGRdSsS1");
        tokenFactory = new TokenFactory();
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

        // Buy tokens
        uint tokenQty = 10;
        tokenFactory.buyMemeToken{value: 1 ether}(memeTokenAddress, tokenQty);

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
        assertEq(fundingRaised, 1 ether);

        // Verify user's balance
        Token token = Token(memeTokenAddress);
        assertEq(token.balanceOf(address(this)), tokenQty * 10 ** 18);

        // Additional field checks
        assertEq(name, "Test Token");
        assertEq(symbol, "TEST");
        assertEq(creatorAddress, address(this));
    }

    function testBuyMemeTokenRevertsOnInsufficientETH() public {
        // Create a meme token
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        // Attempt to buy tokens with insufficient ETH
        uint tokenQty = 100;
        vm.expectRevert(bytes("Incorrect value of ETH sent"));
        tokenFactory.buyMemeToken{value: 0.001 ether}(memeTokenAddress, tokenQty);
    }

   /*  function testFundingGoalTriggersLiquidity() public {
        // Create a meme token
        address memeTokenAddress = tokenFactory.createMemeToken{
            value: 0.0001 ether
        }("Test Token", "TEST", "img://test.png", "This is a test token");

        // Reach the funding goal
        tokenFactory.buyMemeToken{value: 24 ether}(memeTokenAddress, 1000);

        // Verify liquidity pool is created
        // Check console logs for pool and liquidity details
    } */
}
