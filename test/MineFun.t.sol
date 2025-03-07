// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MineFunImplementation.sol";
import {MineFunProxy} from "../src/MineFunProxy.sol"; 
import {Token} from "../src/Token.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract MineFunTest is Test {
    MineFunImplementation tokenFactory;

    address deployer;
    address teamWallet = vm.addr(100); // Simulated team wallet
    address user1 = vm.addr(1);
    address user2 = vm.addr(2);

    function setUp() public {
    deployer = msg.sender;
    string memory rpcUrl = vm.envString("RPC_URL");

    vm.createSelectFork(rpcUrl);
    vm.prank(deployer);

    // Deploy the implementation contract
    MineFunImplementation implementation = new MineFunImplementation();

    // Deploy the proxy and point it to the implementation
    MineFunProxy proxy = new MineFunProxy(address(implementation), "");

    // Cast proxy address as MineFunImplementation to interact with it
    tokenFactory = MineFunImplementation(address(proxy));

    // ✅ Explicitly call initialize() on the proxy
    vm.prank(deployer);
    tokenFactory.initialize(teamWallet);

   

    // Fund users for testing
    vm.deal(user1, 100 ether);
    vm.deal(user2, 100 ether);
    vm.deal(teamWallet, 0 ether); // Ensure team wallet starts empty
}

   function simulateBondingProcess(
    address minedTokenAddress
) public {
    uint fundingAmount = 1 ether; // Initial ETH funding for each wallet
    uint tokensPerMine = 50_000 ether;
    uint maxTokensPerWallet = 10_000_000 ether;
    uint totalTokensBought = 0;

    // ✅ Ensure bonding hasn't happened yet
    (, , , , , uint tokensBought, , , , bool bonded) = tokenFactory.getMinedTokenDetails(
        minedTokenAddress
    );
    require(!bonded, "Token is already bonded");

    uint walletIndex = 1;

    while (!bonded) {
        address wallet = vm.addr(walletIndex); // Get a new wallet
        vm.deal(wallet, fundingAmount); // Fund wallet with ETH
        walletIndex++;

        uint walletTokenBalance = IERC20(minedTokenAddress).balanceOf(wallet);

        vm.startPrank(wallet);

        while (
            walletTokenBalance + tokensPerMine <= maxTokensPerWallet &&
            totalTokensBought + tokensPerMine <= 500_000_000 ether // Adjust for the actual max supply
        ) {
            tokenFactory.mineToken{value: 0.0002 ether}(minedTokenAddress);
            walletTokenBalance += tokensPerMine;
            totalTokensBought += tokensPerMine;

            // Check if bonding is reached
            (, , , , , tokensBought, , , , bonded) = tokenFactory.getMinedTokenDetails(
                minedTokenAddress
            );

            if (bonded) {
                break;
            }
        }

        vm.stopPrank();
    }
}

    /// ✅ **Test that 50% of ETH sent is stored in the team fund**
    function testMineTokenTaxAllocation() public {
        address minedTokenAddress = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "img://test.png",
            "This is a test token",
            3 days
        );

        vm.startPrank(user1);
        tokenFactory.mineToken{value: 0.0002 ether}(minedTokenAddress); // 0.2 ETH sent
        vm.stopPrank();

        uint teamFundBalance = tokenFactory.teamFunds(minedTokenAddress);
        assertEq(
            teamFundBalance,
            0.0002 ether / 2,
            "Team fund should have 50% of mined ETH"
        );
    }

    /// ✅ **Test that the team wallet can retrieve funds only after bonding**
    function testRetrieveTeamFundsAfterBonding() public {
        address minedTokenAddress = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "img://test.png",
            "This is a test token",
            3 days
        );

        simulateBondingProcess(minedTokenAddress);

        // Verify that token bonded
        (, , , , , , , , , bool bonded) = tokenFactory.getMinedTokenDetails(
            minedTokenAddress
        );
        assertTrue(bonded, "Token should be bonded");

        // Team wallet retrieves funds
        vm.startPrank(teamWallet);
        tokenFactory.retrieveTeamFunds(minedTokenAddress);
        vm.stopPrank();

        uint teamFundBalanceAfter = tokenFactory.teamFunds(minedTokenAddress);
        assertEq(teamFundBalanceAfter, 0, "Team funds should be withdrawn");
    }

    /// ✅ **Test that the team wallet cannot retrieve funds if the token fails to bond**
    function testTeamFundRetrievalFailsIfNotBonded() public {
        address minedTokenAddress = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "img://test.png",
            "This is a test token",
            3 days
        );

        vm.startPrank(user1);
        tokenFactory.mineToken{value: 0.0002 ether}(minedTokenAddress); // Not enough to bond
        vm.stopPrank();

        vm.expectRevert("Token did not bond");
        vm.startPrank(teamWallet);
        tokenFactory.retrieveTeamFunds(minedTokenAddress);
        vm.stopPrank();
    }

    /// ✅ **Test that refund correctly includes the team's portion when bonding fails**
    function testRefundIncludesTeamPortion() public {
        address minedTokenAddress = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "img://test.png",
            "This is a test token",
            1 days
        );

        vm.startPrank(user1);
        tokenFactory.mineToken{value: 0.0002 ether}(minedTokenAddress); // 0.2 ETH total (50% to team)
        vm.stopPrank();

        uint initialBalance = user1.balance;

        // Simulate time passing beyond bonding deadline
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(user1);
        tokenFactory.refundContributors(minedTokenAddress);
        vm.stopPrank();

        uint finalBalance = user1.balance;
        assertEq(
            finalBalance,
            initialBalance + 0.0002 ether,
            "User should receive full refund (including team tax)"
        );
    }

    /// ✅ **Test that refund fails after bonding is successful**
    function testRefundFailsAfterBonding() public {
        address minedTokenAddress = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "img://test.png",
            "This is a test token",
            1 days
        );

        simulateBondingProcess(minedTokenAddress);

        // Ensure bonding happened
        (, , , , , , , , , bool bonded) = tokenFactory.getMinedTokenDetails(
            minedTokenAddress
        );
        assertTrue(bonded, "Token should be bonded");

        vm.warp(block.timestamp + 2 days);

        // Refund should fail
        vm.startPrank(user1);
        vm.expectRevert("Token bonded, no refunds available");
        tokenFactory.refundContributors(minedTokenAddress);
        vm.stopPrank();
    }
    /// ✅ **Test that liquidity is added to Uniswap V2 after bonding**
    function testLiquidityAddedAfterBonding() public {
        address minedTokenAddress = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "img://test.png",
            "This is a test token",
            3 days
        );

        Token minedToken = Token(minedTokenAddress);

        // Fetch Uniswap V2 factory address from your contract
        address uniswapFactory = tokenFactory.UNISWAP_V2_FACTORY();
       address routerAddress = address(tokenFactory.router());
       /* console.log("uniswapFactory",uniswapFactory);
       console.log("routerAddress",routerAddress); */

        address WETH = IUniswapV2Router01(routerAddress).WETH();

       // Fetch the Uniswap V2 Pair (minedToken <> WETH)
        address uniswapPair = IUniswapV2Factory(uniswapFactory).getPair(
            address(minedToken),
            WETH
        );

        require(uniswapPair == address(0), "Pair already created");

        // Ensure liquidity is zero before bonding
        uint initialLiquidity = IERC20(minedToken).balanceOf(uniswapPair);
        assertEq(initialLiquidity, 0, "Initial liquidity should be zero");

        simulateBondingProcess(minedTokenAddress);

        // Ensure bonding happened
        (, , , , , , , , , bool bonded) = tokenFactory.getMinedTokenDetails(
            minedTokenAddress
        );
        assertTrue(bonded, "Token should be bonded");

        uniswapPair = IUniswapV2Factory(uniswapFactory).getPair(
            address(minedToken),
            WETH
        );

        // Check that liquidity has been added
        uint finalLiquidity = IERC20(minedToken).balanceOf(
            address(tokenFactory)
        );
        assertGt(finalLiquidity, 0, "Liquidity should be added after bonding");

        uint finalWETHLiq = IERC20(WETH).balanceOf(uniswapPair);
        assertEq(finalWETHLiq, 1 ether); 
    }

    function testGetMinedTokenDetails() public {
        // Token parameters
        string memory name = "Test Token";
        string memory symbol = "TEST";
        string memory description = "This is a test token";
        string memory tokenImageUrl = "img://test.png";
        uint bondingDeadline = 3 days;

        // Create a mined token
        vm.prank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(name, symbol, tokenImageUrl, description, bondingDeadline);

        // Fetch token details
        (
            string memory fetchedName,
            string memory fetchedSymbol,
            string memory fetchedDescription,
            string memory fetchedImageUrl,
            uint fetchedFundingRaised,
            uint fetchedTokensBought,
            uint fetchedBondingDeadline,
            address fetchedTokenAddress,
            address fetchedCreatorAddress,
            bool fetchedBonded
        ) = tokenFactory.getMinedTokenDetails(minedTokenAddress);

        // Assert values
        assertEq(fetchedName, name, "Token name should match");
        assertEq(fetchedSymbol, symbol, "Token symbol should match");
        assertEq(
            fetchedDescription,
            description,
            "Token description should match"
        );
        assertEq(
            fetchedImageUrl,
            tokenImageUrl,
            "Token image URL should match"
        );
        assertEq(fetchedFundingRaised, 0, "Funding raised should start at 0");
        assertEq(fetchedTokensBought, 0, "Tokens bought should start at 0");
        assertEq(
            fetchedBondingDeadline,
            block.timestamp + 3 days,
            "Bonding deadline should match"
        );
        assertEq(
            fetchedTokenAddress,
            minedTokenAddress,
            "Token address should match"
        );
        assertEq(fetchedCreatorAddress, user1, "Creator address should match");
        assertFalse(fetchedBonded, "Token should not be bonded initially");
    }

    function test_Change_Router() public {
        vm.prank(deployer);
        tokenFactory.updateRouterAddress(0x029bE7FB61D3E60c1876F1E0B44506a7108d3c70);
    }

    function test_Change_USDT() public {
        address newUSDT = 0xFE42ea5c89561901FdE0A0101671BC3190E4721e;
        vm.prank(deployer);
        tokenFactory.updateUSDTAddress(newUSDT);

        assert(tokenFactory.USDT()==newUSDT);
    }
}
