// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/upgradeable/MineFun.sol";
import {Token} from "../../src/Token.sol";
import {DepinStaking} from "../../src/DepinStaking.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockERC20} from "../../src/MockERC20.sol";

contract MineFunBondingRefundTest is Test {
    MineFun tokenFactory;
    MockERC20 public mockSolo;
    DepinStaking public depinStaking;

    address deployer;
    address teamWallet = vm.addr(100);
    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    
    uint256 mineCost;

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
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        tokenFactory = MineFun(address(proxy));

        mockSolo = new MockERC20("Mock SOLO", "SOLO");
        
        depinStaking = new DepinStaking();
        tokenFactory.setDepinStakingAddress(address(depinStaking));
        tokenFactory.setSoloTokenAddress(address(mockSolo));
        
        mineCost = tokenFactory.PRICE_PER_MINE();

        vm.stopPrank();

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(teamWallet, 0 ether);
    }

    function simulateBondingProcess(address minedTokenAddress) public {
        uint fundingAmount = 1 ether;
        uint tokensPerMine = 50_000 ether;
        uint maxTokensPerWallet = 10_000_000 ether;
        uint totalTokensBought = 0;

        (, , , , , uint tokensBought, , , , bool bonded) = tokenFactory.getMinedTokenDetails(minedTokenAddress);
        require(!bonded, "Token is already bonded");

        uint walletIndex = 1;

        while (!bonded) {
            address wallet = vm.addr(walletIndex);
            vm.deal(wallet, fundingAmount);
            mockSolo.mint(wallet, 1000 ether);
            walletIndex++;

            uint walletTokenBalance = IERC20(minedTokenAddress).balanceOf(wallet);

            vm.startPrank(wallet);

            while (
                walletTokenBalance + tokensPerMine <= maxTokensPerWallet &&
                totalTokensBought + tokensPerMine <= 500_000_000 ether
            ) {
                tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
                walletTokenBalance += tokensPerMine;
                totalTokensBought += tokensPerMine;

                (, , , , , tokensBought, , , , bonded) = tokenFactory.getMinedTokenDetails(minedTokenAddress);

                if (bonded) {
                    break;
                }
            }

            vm.stopPrank();
        }
    }

    // =========== BONDING TESTS =========== //

    function test_TokenBonding_Success() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        simulateBondingProcess(minedTokenAddress);

        (, , , , , , , , , bool bonded) = tokenFactory.getMinedTokenDetails(minedTokenAddress);
        assertTrue(bonded, "Token should be bonded");
    }

    function test_MineToken_RevertWhen_BondingExpired() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            1 days,
            false,
            0,
            0,
            100 ether
        );

        // Fast forward past bonding deadline
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert("Bonding period expired");
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();
    }

    function test_MineToken_RevertWhen_AlreadyBonded() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        simulateBondingProcess(minedTokenAddress);

        vm.startPrank(user1);
        vm.expectRevert("Token already bonded");
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();
    }

    function test_MineToken_RevertWhen_MaxPerWalletReached() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            7 days, // Longer bonding time to avoid auto-bonding
            false,
            0,
            0,
            100 ether
        );

        uint256 tokensPerMine = tokenFactory.TOKENS_PER_MINE();
        uint256 maxPerWallet = tokenFactory.MAX_PER_WALLET();
        uint256 minesNeeded = maxPerWallet / tokensPerMine;

        // Mine up to the max per wallet limit
        for (uint256 i = 0; i < minesNeeded; i++) {
            tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
            
            // Check if bonding happened early and break if so
            (, , , , , , , , , bool bonded) = tokenFactory.getMinedTokenDetails(minedTokenAddress);
            if (bonded) {
                // If it bonded early, we can't test max per wallet
                vm.stopPrank();
                return;
            }
        }

        // Try to mine one more time, should fail
        vm.expectRevert("Maximum mine per wallet reached");
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();
    }

    // =========== REFUND TESTS =========== //

    function test_RefundContributors_Success() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            1 days,
            false,
            0,
            0,
            100 ether
        );

        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        uint256 balanceBefore = user1.balance;
        
        // Fast forward past bonding deadline
        vm.warp(block.timestamp + 2 days);

        tokenFactory.refundContributors(minedTokenAddress);
        
        uint256 balanceAfter = user1.balance;
        assertEq(balanceAfter, balanceBefore + mineCost, "User should get full refund");
        
        uint256 tokenBalance = IERC20(minedTokenAddress).balanceOf(user1);
        assertEq(tokenBalance, 0, "User tokens should be burned");
        vm.stopPrank();
    }

    function test_RefundContributors_RevertWhen_DeadlineNotReached() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );

        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);

        vm.expectRevert("Bonding deadline not reached");
        tokenFactory.refundContributors(minedTokenAddress);
        vm.stopPrank();
    }

    function test_RefundContributors_RevertWhen_TokenBonded() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        simulateBondingProcess(minedTokenAddress);

        vm.warp(block.timestamp + 4 days);

        vm.startPrank(user1);
        vm.expectRevert("Token bonded, no refunds available");
        tokenFactory.refundContributors(minedTokenAddress);
        vm.stopPrank();
    }

    function test_RefundContributors_RevertWhen_NoContribution() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            1 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        vm.startPrank(user2);
        vm.expectRevert("No contribution found");
        tokenFactory.refundContributors(minedTokenAddress);
        vm.stopPrank();
    }

    // =========== TEAM FUND RETRIEVAL TESTS =========== //

    function test_RetrieveTeamFunds_Success() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        simulateBondingProcess(minedTokenAddress);

        uint256 teamFundsBefore = tokenFactory.teamFunds(minedTokenAddress);
        uint256 teamBalanceBefore = teamWallet.balance;

        vm.startPrank(teamWallet);
        tokenFactory.retrieveTeamFunds(minedTokenAddress);
        vm.stopPrank();

        uint256 teamFundsAfter = tokenFactory.teamFunds(minedTokenAddress);
        uint256 teamBalanceAfter = teamWallet.balance;

        assertEq(teamFundsAfter, 0, "Team funds should be zero after retrieval");
        assertEq(teamBalanceAfter, teamBalanceBefore + teamFundsBefore, "Team wallet should receive funds");
    }

    function test_RetrieveTeamFunds_RevertWhen_NotBonded() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );

        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();

        vm.startPrank(teamWallet);
        vm.expectRevert("Token did not bond");
        tokenFactory.retrieveTeamFunds(minedTokenAddress);
        vm.stopPrank();
    }

    function test_RetrieveTeamFunds_RevertWhen_NotAuthorized() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        simulateBondingProcess(minedTokenAddress);

        vm.startPrank(user1);
        vm.expectRevert("Not authorized");
        tokenFactory.retrieveTeamFunds(minedTokenAddress);
        vm.stopPrank();
    }

    function test_RetrieveTeamFunds_RevertWhen_NoFunds() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        simulateBondingProcess(minedTokenAddress);

        vm.startPrank(teamWallet);
        tokenFactory.retrieveTeamFunds(minedTokenAddress); // First retrieval
        
        vm.expectRevert("No funds available");
        tokenFactory.retrieveTeamFunds(minedTokenAddress); // Second retrieval should fail
        vm.stopPrank();
    }

    // =========== PROXY CREATION TESTS =========== //

    function test_CreateMinedToken_ProxyCreation_Success() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            true, // proxy creation
            block.timestamp + 1,
            block.number + 1,
            100 ether
        );
        vm.stopPrank();

        assertTrue(minedTokenAddress != address(0), "Token should be created with proxy creation");
    }

    function test_CreateMinedToken_ProxyCreation_RevertWhen_InvalidTimestamp() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        vm.expectRevert("Invalid timestamp");
        tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            true, // proxy creation
            0, // invalid timestamp
            block.number + 1,
            100 ether
        );
        vm.stopPrank();
    }

    function test_CreateMinedToken_ProxyCreation_RevertWhen_InvalidBlockNumber() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        vm.expectRevert("Invalid block number");
        tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            true, // proxy creation
            block.timestamp + 1,
            0, // invalid block number
            100 ether
        );
        vm.stopPrank();
    }
}