// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/upgradeable/MineFun.sol";
import {Token} from "../../src/Token.sol";
import {DepinStaking} from "../../src/MockDepinStaking.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC6909} from "../../src/ERC6909.sol";  
import {MockERC20} from "../../src/MockERC20.sol";  

contract MockERC6909 is ERC6909 {
        function mint(address to, uint256 tokenId, uint256 amount) public {
        _mint(to, tokenId, amount);
    }
}

contract DepinStakingMiningTest is Test {
    MineFun tokenFactory;
    DepinStaking public depinStaking;
    MockERC6909 public depinNFT;
    MockERC20 public mockStSolo;
    MockERC20 public mockSolo;

    uint256 mineCost;

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
        depinNFT = new MockERC6909();

        depinStaking = new DepinStaking();
        tokenFactory.setDepinStakingAddress(address(depinStaking));
        mineCost = tokenFactory.PRICE_PER_MINE();

        vm.stopPrank();

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(teamWallet, 0 ether);
    }

    function simulateBondingProcess(address minedTokenAddress) public {
        uint fundingAmount = 1 ether; // Initial ETH funding for each wallet
        uint tokensPerMine = 50_000 ether;
        uint maxTokensPerWallet = 10_000_000 ether;
        uint totalTokensBought = 0;

        // Ensure bonding hasn't happened yet
        (, , , , , uint tokensBought, , , , bool bonded) = tokenFactory
            .getMinedTokenDetails(minedTokenAddress);
        require(!bonded, "Token is already bonded");

        uint walletIndex = 1;

        while (!bonded) {
            address wallet = vm.addr(walletIndex); // Get a new wallet
            vm.deal(wallet, fundingAmount); // Fund wallet with ETH
            walletIndex++;

            uint walletTokenBalance = IERC20(minedTokenAddress).balanceOf(
                wallet
            );

            vm.startPrank(wallet);

            while (
                walletTokenBalance + tokensPerMine <= maxTokensPerWallet &&
                totalTokensBought + tokensPerMine <= 500_000_000 ether // Adjust for the actual max supply
            ) {
                tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
                walletTokenBalance += tokensPerMine;
                totalTokensBought += tokensPerMine;

                // Check if bonding is reached
                (, , , , , tokensBought, , , , bonded) = tokenFactory
                    .getMinedTokenDetails(minedTokenAddress);

                if (bonded) {
                    break;
                }
            }

            vm.stopPrank();
        }
    }

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
    //     tokenFactory.mineToken{value: mineCost}(minedTokenAddress); // 0.2 ETH sent
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

    function test_DepinStakeMining() public {
        vm.startPrank(deployer);
        tokenFactory.setSoloTokenAddress(address(mockSolo));
        vm.stopPrank();

        address minedTokenAddress = tokenFactory.createMinedToken{
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

        Token minedToken = Token(minedTokenAddress);

        // Amount of tokens per mine
        uint256 tokensPerMine = tokenFactory.TOKENS_PER_MINE();

        //user 2 mines and receives correct amount of tokens
        vm.startPrank(user2);
        assert(minedToken.balanceOf(user2) == 0);
        tokenFactory.mineToken{value: mineCost}(address(minedToken));
        assert(minedToken.balanceOf(user2) == tokensPerMine);
        vm.stopPrank();

        // User 1 mints a Depin NFT and stakes it
        vm.startPrank(user1);
        depinNFT.mint(user1, 1, 1);
        assertTrue(depinNFT.balanceOf(user1, 1) == 1);
        depinNFT.approve(address(depinStaking), 1, 1);
        depinStaking.stake(address(depinNFT), 1, 1);
        assertTrue(depinStaking.isStaking(user1));

        //user 2 mines and receives Double amount of tokens
        assert(minedToken.balanceOf(user1) == 0);
        tokenFactory.mineToken{value: mineCost}(address(minedToken));
        assert(minedToken.balanceOf(user1) == tokensPerMine * 2);

        vm.stopPrank();

        // Fetch Uniswap V2 factory address from your contract
        address uniswapFactory = tokenFactory.UNISWAP_V2_FACTORY();
        address routerAddress = address(tokenFactory.router());

        address WETH = IUniswapV2Router01(routerAddress).WETH();

        //     // Fetch the Uniswap V2 Pair (minedToken <> WETH)
        address uniswapPair = IUniswapV2Factory(uniswapFactory).getPair(
            address(minedToken),
            WETH
        );

        require(uniswapPair == address(0), "Pair already created");

        // Ensure liquidity is zero before bonding
        uint initialLiquidity = IERC20(minedToken).balanceOf(uniswapPair);
        assertEq(initialLiquidity, 0, "Initial liquidity should be zero");

        simulateBondingProcess(minedTokenAddress);

        //     // Ensure bonding happened
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
        assert(finalWETHLiq >= tokenFactory.MINEDTOKEN_FUNDING_GOAL());
    }
}
