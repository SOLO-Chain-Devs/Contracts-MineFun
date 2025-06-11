// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/upgradeable/MineFun.sol";
import {Token} from "../../src/Token.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MockERC20} from "../../src/MockERC20.sol";

contract MineFunTest is Test {
    MineFun tokenFactory;

    MockERC20 public mockStSolo;
    MockERC20 public mockSolo;

    address deployer;
    address teamWallet = vm.addr(100); // Simulated team wallet
    address user1 = vm.addr(1);
    address user2 = vm.addr(2);

    function setUp() public {
        deployer = msg.sender;
        string memory rpcUrl = vm.envString("RPC_URL");
        address uniswap_v2_router_ca = vm.envAddress("UNISWAP_V2_ROUTER_CA");
        address uniswap_v2_factory_ca = vm.envAddress("UNISWAP_V2_FACTORY_CA");
        address usdt_ca = vm.envAddress("USDT_CA");

        vm.createSelectFork(rpcUrl);
        vm.startPrank(deployer);

        MineFun implementation = new MineFun();
        bytes memory initData = abi.encodeWithSelector(
            MineFun.initialize.selector,
            teamWallet,
            uniswap_v2_router_ca,
            uniswap_v2_factory_ca,
            usdt_ca
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        tokenFactory = MineFun(address(proxy));

        mockStSolo = new MockERC20("Mock stSOLO", "stSOLO");
        mockSolo = new MockERC20("Mock SOLO", "SOLO");

        vm.stopPrank();

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(teamWallet, 0 ether);
    }

    // function simulateBondingProcess(address minedTokenAddress) public {
    //     uint fundingAmount = 1 ether; // Initial ETH funding for each wallet
    //     uint tokensPerMine = 50_000 ether;
    //     uint maxTokensPerWallet = 10_000_000 ether;
    //     uint totalTokensBought = 0;

    //     // Ensure bonding hasn't happened yet
    //     (, , , , , uint tokensBought, , , , bool bonded) = tokenFactory
    //         .getMinedTokenDetails(minedTokenAddress);
    //     require(!bonded, "Token is already bonded");

    //     uint walletIndex = 1;

    //     while (!bonded) {
    //         address wallet = vm.addr(walletIndex); // Get a new wallet
    //         vm.deal(wallet, fundingAmount); // Fund wallet with ETH
    //         walletIndex++;

    //         uint walletTokenBalance = IERC20(minedTokenAddress).balanceOf(
    //             wallet
    //         );

    //         vm.startPrank(wallet);

    //         while (
    //             walletTokenBalance + tokensPerMine <= maxTokensPerWallet &&
    //             totalTokensBought + tokensPerMine <= 500_000_000 ether // Adjust for the actual max supply
    //         ) {
    //             tokenFactory.mineToken{value: 0.0002 ether}(minedTokenAddress);
    //             walletTokenBalance += tokensPerMine;
    //             totalTokensBought += tokensPerMine;

    //             // Check if bonding is reached
    //             (, , , , , tokensBought, , , , bonded) = tokenFactory
    //                 .getMinedTokenDetails(minedTokenAddress);

    //             if (bonded) {
    //                 break;
    //             }
    //         }

    //         vm.stopPrank();
    //     }
    // }

    // function testMineTokenTaxAllocation() public {
    //     vm.startPrank(deployer);
    //     tokenFactory.setSoloTokenAddress(address(mockSolo));
    //     vm.stopPrank();

    //     address minedTokenAddress = tokenFactory.createMinedToken{
    //         value: 0.0001 ether
    //     }(
    //         "Test Token",
    //         "TEST",
    //         "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
    //         "img://test.png",
    //         3 days,
    //         false,
    //         0,
    //         0,
    //         10
    //     );

    //     vm.startPrank(user1);
    //     tokenFactory.mineToken{value: 0.0002 ether}(minedTokenAddress); // 0.2 ETH sent
    //     vm.stopPrank();

    //     uint teamFundBalance = tokenFactory.teamFunds(minedTokenAddress);
    //     assertEq(
    //         teamFundBalance,
    //         0.0002 ether / 2,
    //         "Team fund should have 50% of mined ETH"
    //     );
    // }

    // function testRetrieveTeamFundsAfterBonding() public {
    //     vm.startPrank(deployer);
    //     tokenFactory.setSoloTokenAddress(address(mockSolo));
    //     vm.stopPrank();

    //     address minedTokenAddress = tokenFactory.createMinedToken{
    //         value: 0.0001 ether
    //     }(
    //         "Test Token",
    //         "TEST",
    //         "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
    //         "img://test.png",
    //         3 days,
    //         false,
    //         0,
    //         0,
    //         10
    //     );

    //     simulateBondingProcess(minedTokenAddress);

    //     // Verify that token bonded
    //     (, , , , , , , , , bool bonded) = tokenFactory.getMinedTokenDetails(
    //         minedTokenAddress
    //     );
    //     assertTrue(bonded, "Token should be bonded");

    //     // Team wallet retrieves funds
    //     vm.startPrank(teamWallet);
    //     tokenFactory.retrieveTeamFunds(minedTokenAddress);
    //     vm.stopPrank();

    //     uint teamFundBalanceAfter = tokenFactory.teamFunds(minedTokenAddress);
    //     assertEq(teamFundBalanceAfter, 0, "Team funds should be withdrawn");
    // }

    // function testTeamFundRetrievalFailsIfNotBonded() public {
    //     vm.startPrank(deployer);
    //     tokenFactory.setSoloTokenAddress(address(mockSolo));
    //     vm.stopPrank();

    //     address minedTokenAddress = tokenFactory.createMinedToken{
    //         value: 0.0001 ether
    //     }(
    //         "Test Token",
    //         "TEST",
    //         "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
    //         "img://test.png",
    //         3 days,
    //         false,
    //         0,
    //         0,
    //         0
    //     );

    //     vm.startPrank(user1);
    //     tokenFactory.mineToken{value: 0.0002 ether}(minedTokenAddress); // Not enough to bond
    //     vm.stopPrank();

    //     vm.expectRevert("Token did not bond");
    //     vm.startPrank(teamWallet);
    //     tokenFactory.retrieveTeamFunds(minedTokenAddress);
    //     vm.stopPrank();
    // }

    // function testRefundIncludesTeamPortion() public {
    //     vm.startPrank(deployer);
    //     tokenFactory.setSoloTokenAddress(address(mockSolo));
    //     vm.stopPrank();

    //     address minedTokenAddress = tokenFactory.createMinedToken{
    //         value: 0.0001 ether
    //     }(
    //         "Test Token",
    //         "TEST",
    //         "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
    //         "img://test.png",
    //         1 days,
    //         false,
    //         0,
    //         0,
    //         10
    //     );

    //     vm.startPrank(user1);
    //     tokenFactory.mineToken{value: 0.0002 ether}(minedTokenAddress); // 0.2 ETH total (50% to team)
    //     vm.stopPrank();

    //     uint initialBalance = user1.balance;

    //     // Simulate time passing beyond bonding deadline
    //     vm.warp(block.timestamp + 2 days);

    //     vm.startPrank(user1);
    //     tokenFactory.refundContributors(minedTokenAddress);
    //     vm.stopPrank();

    //     uint finalBalance = user1.balance;
    //     assertEq(
    //         finalBalance,
    //         initialBalance + 0.0002 ether,
    //         "User should receive full refund (including team tax)"
    //     );
    // }

    // function testRefundFailsAfterBonding() public {
    //     vm.startPrank(deployer);
    //     tokenFactory.setSoloTokenAddress(address(mockSolo));
    //     vm.stopPrank();

    //     address minedTokenAddress = tokenFactory.createMinedToken{
    //         value: 0.0001 ether
    //     }(
    //         "Test Token",
    //         "TEST",
    //         "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
    //         "img://test.png",
    //         1 days,
    //         false,
    //         0,
    //         0,
    //         10
    //     );

    //     simulateBondingProcess(minedTokenAddress);

    //     // Ensure bonding happened
    //     (, , , , , , , , , bool bonded) = tokenFactory.getMinedTokenDetails(
    //         minedTokenAddress
    //     );
    //     assertTrue(bonded, "Token should be bonded");

    //     vm.warp(block.timestamp + 2 days);

    //     // Refund should fail
    //     vm.startPrank(user1);
    //     vm.expectRevert("Token bonded, no refunds available");
    //     tokenFactory.refundContributors(minedTokenAddress);
    //     vm.stopPrank();
    // }

    // function testLiquidityAddedAfterBonding() public {
    //     vm.startPrank(deployer);
    //     tokenFactory.setSoloTokenAddress(address(mockSolo));
    //     vm.stopPrank();

    //     address minedTokenAddress = tokenFactory.createMinedToken{
    //         value: 0.0001 ether
    //     }(
    //         "Test Token",
    //         "TEST",
    //         "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
    //         "img://test.png",
    //         3 days,
    //         false,
    //         0,
    //         0,
    //         1
    //     );

    //     Token minedToken = Token(minedTokenAddress);

    //     // Fetch Uniswap V2 factory address from your contract
    //     address uniswapFactory = tokenFactory.UNISWAP_V2_FACTORY();
    //     address routerAddress = address(tokenFactory.router());

    //     address WETH = IUniswapV2Router01(routerAddress).WETH();

    //     // Fetch the Uniswap V2 Pair (minedToken <> WETH)
    //     address uniswapPair = IUniswapV2Factory(uniswapFactory).getPair(
    //         address(minedToken),
    //         WETH
    //     );

    //     require(uniswapPair == address(0), "Pair already created");

    //     // Ensure liquidity is zero before bonding
    //     uint initialLiquidity = IERC20(minedToken).balanceOf(uniswapPair);
    //     assertEq(initialLiquidity, 0, "Initial liquidity should be zero");

    //     simulateBondingProcess(minedTokenAddress);

    //     // Ensure bonding happened
    //     (, , , , , , , , , bool bonded) = tokenFactory.getMinedTokenDetails(
    //         minedTokenAddress
    //     );
    //     assertTrue(bonded, "Token should be bonded");

    //     uniswapPair = IUniswapV2Factory(uniswapFactory).getPair(
    //         address(minedToken),
    //         WETH
    //     );

    //     // Check that liquidity has been added
    //     uint finalLiquidity = IERC20(minedToken).balanceOf(
    //         address(tokenFactory)
    //     );
    //     assertGt(finalLiquidity, 0, "Liquidity should be added after bonding");

    //     uint finalWETHLiq = IERC20(WETH).balanceOf(uniswapPair);
    //     assertEq(finalWETHLiq, 1 ether);
    // }

    // function testGetMinedTokenDetails() public {
    //     // Token parameters
    //     string memory name = "Test Token";
    //     string memory symbol = "TEST";
    //     string
    //         memory metadataCID = "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24";
    //     string memory tokenImageCID = "img://test.png";
    //     uint bondingDeadline = 3 days;

    //     // Create a mined token
    //     vm.prank(user1);
    //     address minedTokenAddress = tokenFactory.createMinedToken{
    //         value: 0.0001 ether
    //     }(
    //         name,
    //         symbol,
    //         metadataCID,
    //         tokenImageCID,
    //         bondingDeadline,
    //         false,
    //         0,
    //         0,
    //         10
    //     );

    //     // Fetch token details
    //     (
    //         string memory fetchedName,
    //         string memory fetchedSymbol,
    //         string memory fetchedMetadataCID,
    //         string memory fetchedImageCID,
    //         uint fetchedFundingRaised,
    //         uint fetchedTokensBought,
    //         uint fetchedBondingDeadline,
    //         address fetchedTokenAddress,
    //         address fetchedCreatorAddress,
    //         bool fetchedBonded
    //     ) = tokenFactory.getMinedTokenDetails(minedTokenAddress);

    //     // Assert values
    //     assertEq(fetchedName, name, "Token name should match");
    //     assertEq(fetchedSymbol, symbol, "Token symbol should match");
    //     assertEq(
    //         fetchedMetadataCID,
    //         metadataCID,
    //         "Token CID Metadata should match"
    //     );
    //     assertEq(
    //         fetchedImageCID,
    //         tokenImageCID,
    //         "Token image URL should match"
    //     );
    //     assertEq(fetchedFundingRaised, 0, "Funding raised should start at 0");
    //     assertEq(fetchedTokensBought, 0, "Tokens bought should start at 0");
    //     assertEq(
    //         fetchedBondingDeadline,
    //         block.timestamp + 3 days,
    //         "Bonding deadline should match"
    //     );
    //     assertEq(
    //         fetchedTokenAddress,
    //         minedTokenAddress,
    //         "Token address should match"
    //     );
    //     assertEq(fetchedCreatorAddress, user1, "Creator address should match");
    //     assertFalse(fetchedBonded, "Token should not be bonded initially");
    // }

    // function test_Change_Router() public {
    //     vm.prank(deployer);
    //     tokenFactory.updateRouterAddress(
    //         0x029bE7FB61D3E60c1876F1E0B44506a7108d3c70
    //     );
    // }

    // function test_Change_USDT() public {
    //     address newUSDT = 0xFE42ea5c89561901FdE0A0101671BC3190E4721e;
    //     vm.prank(deployer);
    //     tokenFactory.updateUSDTAddress(newUSDT);

    //     assert(tokenFactory.USDT() == newUSDT);

    //     vm.prank(user1);
    //     vm.expectRevert();
    //     tokenFactory.updateUSDTAddress(newUSDT);
    // }

    // function testUpdateTeamWallet() public {
    //     address newTeamWallet = vm.addr(200); // New team wallet address

    //     // Ensure the original team wallet is set
    //     assertEq(tokenFactory.teamWallet(), teamWallet);

    //     // Update team wallet
    //     vm.prank(deployer);
    //     tokenFactory.updateTeamWallet(newTeamWallet);

    //     // Verify team wallet was updated
    //     assertEq(tokenFactory.teamWallet(), newTeamWallet);

    //     // Ensure non-owners cannot update team wallet
    //     vm.prank(user1);
    //     vm.expectRevert();
    //     tokenFactory.updateTeamWallet(vm.addr(300));
    // }

    // ============== Paywalling token creating and mining ============ //

    // Set Solo token address and revert when not the owener
    function testSetSoloTokenAddress() public {
        vm.startPrank(deployer);
        MockERC20 mockToken = new MockERC20("Mock SOLO", "SOLO");
        address soloTokenAddress = address(mockToken);
        address intialSoloTokenAddress = tokenFactory.soloTokenAddress();

        assertEq(
            intialSoloTokenAddress,
            address(0),
            "Before set, Solo token address should be zero"
        );

        tokenFactory.setSoloTokenAddress(soloTokenAddress);
        address updatedSoloTokenAddress = tokenFactory.soloTokenAddress();
        assertEq(
            updatedSoloTokenAddress,
            soloTokenAddress,
            "Solo Token address should change after setting"
        );

        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("OwnableUnauthorizedAccount(address)")),
                user1
            )
        );
        tokenFactory.setSoloTokenAddress(address(0));

        vm.stopPrank();
    }

    function testMineToken_RevertWhen_SoloAddressIsNotSet() public {
        vm.startPrank(deployer);
        MockERC20 mockToken = new MockERC20("Mock SOLO", "SOLO");
        mockToken.mint(user1, 1000 ether);
        vm.stopPrank();
        vm.startPrank(user1);

        address createdTokenAdd = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            0
        );

        vm.expectRevert("Solo token address not set");
        tokenFactory.mineToken{value: 0.0002 ether}(createdTokenAdd);

        vm.stopPrank();
    }

    function testMineToken_RevertWhen_CallerIsNotSoloHolder() public {
        vm.startPrank(deployer);
        MockERC20 mockToken = new MockERC20("Mock SOLO", "SOLO");

        mockToken.mint(user1, 999 ether);
        tokenFactory.setSoloTokenAddress(address(mockToken));
        vm.stopPrank();

        vm.startPrank(user1);

        address createdTokenAdd = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            1000 ether
        );

        vm.expectRevert(
            "You must hold a certain amount of Solo token to be able to mine."
        );
        tokenFactory.mineToken{value: 0.0002 ether}(createdTokenAdd);

        vm.stopPrank();
    }

    function testMineToken_CallerIsSoloHolder() public {
        vm.startPrank(deployer);
        MockERC20 mockToken = new MockERC20("Mock SOLO", "SOLO");

        mockToken.mint(user1, 1000 ether);
        tokenFactory.setSoloTokenAddress(address(mockToken));

        vm.stopPrank();

        vm.startPrank(user1);

        address createdTokenAdd = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            1000 ether
        );

        address createdTokenAdd2 = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "fffest Token",
            "TEasdfST",
            "bafkreiculfgfff5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            0 ether
        );

        tokenFactory.mineToken{value: 0.0002 ether}(createdTokenAdd);
        tokenFactory.mineToken{value: 0.0002 ether}(createdTokenAdd2);

        vm.stopPrank();
    }

    function testUpdateSoloRequiredToMine_UpdatesSuccessfully() public {
        vm.startPrank(user1);

        address createdTokenAdd = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            1000 ether
        );

        (, , , , , , , , address creatorAddress, ) = tokenFactory
            .getMinedTokenDetails(createdTokenAdd);
        assertEq(creatorAddress, user1, "Creator should be user1");

        tokenFactory.updateSoloRequiredToMine(createdTokenAdd, 2000 ether);

        (, , , , , , , , address fetchedCreator, ) = tokenFactory
            .getMinedTokenDetails(createdTokenAdd);

        assertEq(fetchedCreator, user1, "Creator should remain user1");

        // Assuming you expose this for test verification or access mapping directly
        (, , , , , , , , , , uint actualSoloRequirement) = tokenFactory
            .addressToMinedTokenMapping(createdTokenAdd);
        assertEq(
            actualSoloRequirement,
            2000 ether,
            "Solo requirement should update"
        );

        vm.stopPrank();
    }

    function testUpdateSoloRequiredToMine_RevertWhen_NotCreator() public {
        vm.startPrank(user1);

        address createdTokenAdd = tokenFactory.createMinedToken{
            value: 0.0001 ether
        }(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            1000 ether
        );

        vm.stopPrank();

        vm.startPrank(user2);

        vm.expectRevert("Not token creator");
        tokenFactory.updateSoloRequiredToMine(createdTokenAdd, 500 ether);

        vm.stopPrank();
    }
}
