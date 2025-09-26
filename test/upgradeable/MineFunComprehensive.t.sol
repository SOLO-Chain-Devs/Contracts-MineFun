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

contract MineFunComprehensiveTest is Test {
    MineFun tokenFactory;
    MockERC20 public mockSolo;
    DepinStaking public depinStaking;

    address deployer;
    address teamWallet = vm.addr(100);
    address user1 = vm.addr(1);
    address user2 = vm.addr(2);
    address user3 = vm.addr(3);

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

        vm.stopPrank();

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(teamWallet, 0 ether);
    }

    // =========== ADMIN FUNCTIONS TESTS =========== //

    function test_UpdateUSDTAddress_Success() public {
        address newUSDT = 0xFE42ea5c89561901FdE0A0101671BC3190E4721e;
        
        vm.startPrank(deployer);
        tokenFactory.updateUSDTAddress(newUSDT);
        vm.stopPrank();

        assertEq(tokenFactory.USDT(), newUSDT, "USDT address should be updated");
    }

    function test_UpdateUSDTAddress_RevertWhen_ZeroAddress() public {
        vm.startPrank(deployer);
        vm.expectRevert("Invalid address");
        tokenFactory.updateUSDTAddress(address(0));
        vm.stopPrank();
    }

    function test_UpdateUSDTAddress_RevertWhen_NotOwner() public {
        address newUSDT = 0xFE42ea5c89561901FdE0A0101671BC3190E4721e;
        
        vm.startPrank(user1);
        vm.expectRevert();
        tokenFactory.updateUSDTAddress(newUSDT);
        vm.stopPrank();
    }

    function test_UpdateRouterAddress_Success() public {
        address newRouter = 0x029bE7FB61D3E60c1876F1E0B44506a7108d3c70;
        
        vm.startPrank(deployer);
        tokenFactory.updateRouterAddress(newRouter);
        vm.stopPrank();

        assertEq(tokenFactory.UNISWAP_V2_ROUTER(), newRouter, "Router address should be updated");
        assertEq(address(tokenFactory.router()), newRouter, "Router interface should be updated");
    }

    function test_UpdateRouterAddress_RevertWhen_ZeroAddress() public {
        vm.startPrank(deployer);
        vm.expectRevert("Invalid address");
        tokenFactory.updateRouterAddress(address(0));
        vm.stopPrank();
    }

    function test_UpdateRouterAddress_RevertWhen_NotOwner() public {
        address newRouter = 0x029bE7FB61D3E60c1876F1E0B44506a7108d3c70;
        
        vm.startPrank(user1);
        vm.expectRevert();
        tokenFactory.updateRouterAddress(newRouter);
        vm.stopPrank();
    }

    function test_UpdateTeamWallet_Success() public {
        address newTeamWallet = vm.addr(200);

        assertEq(tokenFactory.teamWallet(), teamWallet, "Initial team wallet should match");

        vm.startPrank(deployer);
        tokenFactory.updateTeamWallet(newTeamWallet);
        vm.stopPrank();

        assertEq(tokenFactory.teamWallet(), newTeamWallet, "Team wallet should be updated");
    }

    function test_UpdateTeamWallet_RevertWhen_ZeroAddress() public {
        vm.startPrank(deployer);
        vm.expectRevert("Invalid team wallet address");
        tokenFactory.updateTeamWallet(address(0));
        vm.stopPrank();
    }

    function test_UpdateTeamWallet_RevertWhen_NotOwner() public {
        address newTeamWallet = vm.addr(200);
        
        vm.startPrank(user1);
        vm.expectRevert();
        tokenFactory.updateTeamWallet(newTeamWallet);
        vm.stopPrank();
    }

    // =========== CORE FUNCTIONS TESTS =========== //

    function test_SetSoloTokenAddress_Success() public {
        MockERC20 newSoloToken = new MockERC20("New SOLO", "NSOLO");
        
        vm.startPrank(deployer);
        tokenFactory.setSoloTokenAddress(address(newSoloToken));
        vm.stopPrank();

        assertEq(tokenFactory.soloTokenAddress(), address(newSoloToken), "Solo token address should be updated");
    }

    function test_SetSoloTokenAddress_RevertWhen_NotOwner() public {
        MockERC20 newSoloToken = new MockERC20("New SOLO", "NSOLO");
        
        vm.startPrank(user1);
        vm.expectRevert();
        tokenFactory.setSoloTokenAddress(address(newSoloToken));
        vm.stopPrank();
    }

    function test_SetDepinStakingAddress_Success() public {
        DepinStaking newDepinStaking = new DepinStaking();
        
        vm.startPrank(deployer);
        tokenFactory.setDepinStakingAddress(address(newDepinStaking));
        vm.stopPrank();

        assertEq(address(tokenFactory.depinStakingContract()), address(newDepinStaking), "Depin staking address should be updated");
    }

    function test_SetDepinStakingAddress_RevertWhen_NotOwner() public {
        DepinStaking newDepinStaking = new DepinStaking();
        
        vm.startPrank(user1);
        vm.expectRevert();
        tokenFactory.setDepinStakingAddress(address(newDepinStaking));
        vm.stopPrank();
    }

    function test_CreateMinedToken_Success() public {
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

        assertTrue(minedTokenAddress != address(0), "Token should be created");
        
        (string memory name, string memory symbol,,,,,,, address creator,) = tokenFactory.getMinedTokenDetails(minedTokenAddress);
        assertEq(name, "Test Token", "Token name should match");
        assertEq(symbol, "TEST", "Token symbol should match");
        assertEq(creator, user1, "Creator should be user1");
    }

    function test_CreateMinedToken_RevertWhen_InsufficientFee() public {
        vm.startPrank(user1);
        vm.expectRevert("Insufficient creation fee");
        tokenFactory.createMinedToken{value: 0.00005 ether}(
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
    }

    function test_CreateMinedToken_RevertWhen_InvalidBondingTime() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Bonding time must be between 1 and 7 days");
        tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            8 days, // Too long
            false,
            0,
            0,
            100 ether
        );

        vm.expectRevert("Bonding time must be between 1 and 7 days");
        tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            30 seconds, // Too short
            false,
            0,
            0,
            100 ether
        );
        
        vm.stopPrank();
    }

    function test_CreateMinedToken_RevertWhen_NameTooLong() public {
        vm.startPrank(user1);
        vm.expectRevert("Token name too long");
        tokenFactory.createMinedToken{value: 0.0001 ether}(
            "This is a very long token name that exceeds twenty characters",
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
    }

    function test_CreateMinedToken_RevertWhen_SymbolTooLong() public {
        vm.startPrank(user1);
        vm.expectRevert("Token symbol too long");
        tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "VERYLONGSYMBOL",
            "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24",
            "img://test.png",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();
    }

    function test_MineToken_Success_NoStaking() public {
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

        uint256 mineCost = tokenFactory.PRICE_PER_MINE();
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();

        uint256 userBalance = IERC20(minedTokenAddress).balanceOf(user1);
        assertEq(userBalance, tokenFactory.TOKENS_PER_MINE(), "User should receive tokens");
        
        uint256 teamFunds = tokenFactory.teamFunds(minedTokenAddress);
        assertEq(teamFunds, mineCost / 2, "Team should receive 50% of mining cost");
    }

    function test_MineToken_RevertWhen_TokenNotFound() public {
        mockSolo.mint(user1, 1000 ether);
        address fakeToken = vm.addr(999);
        
        vm.startPrank(user1);
        uint256 mineCost = tokenFactory.PRICE_PER_MINE();
        vm.expectRevert("Token not found");
        tokenFactory.mineToken{value: mineCost}(fakeToken);
        vm.stopPrank();
    }

    function test_MineToken_RevertWhen_SoloAddressNotSet() public {
        vm.startPrank(deployer);
        tokenFactory.setSoloTokenAddress(address(0));
        vm.stopPrank();

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

        uint256 mineCost = tokenFactory.PRICE_PER_MINE();
        vm.expectRevert("Solo token address not set");
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();
    }

    function test_MineToken_RevertWhen_InsufficientSolo() public {
        mockSolo.mint(user1, 50 ether); // Less than required
        
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

        uint256 mineCost = tokenFactory.PRICE_PER_MINE();
        vm.expectRevert("You must hold a certain amount of Solo token to be able to mine.");
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();
    }

    function test_MineToken_RevertWhen_IncorrectETH() public {
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

        vm.expectRevert("Incorrect ETH amount sent");
        tokenFactory.mineToken{value: 0.0001 ether}(minedTokenAddress); // Wrong amount
        vm.stopPrank();
    }

    function test_UpdateSoloRequiredToMine_Success() public {
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

        tokenFactory.updateSoloRequiredToMine(minedTokenAddress, 500 ether);
        
        // Verify the update worked by checking if the creator can still update it
        tokenFactory.updateSoloRequiredToMine(minedTokenAddress, 600 ether);
        vm.stopPrank();
    }

    function test_UpdateSoloRequiredToMine_RevertWhen_NotCreator() public {
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

        vm.startPrank(user2);
        vm.expectRevert("Not token creator");
        tokenFactory.updateSoloRequiredToMine(minedTokenAddress, 500 ether);
        vm.stopPrank();
    }

    // =========== VIEW FUNCTIONS TESTS =========== //

    function test_GetAllMinedTokens_EmptyInitially() public {
        IMineFun.MinedTokenView[] memory allTokens = tokenFactory.getAllMinedTokens();
        assertEq(allTokens.length, 0, "Should be no tokens initially");
    }

    function test_GetAllMinedTokens_AfterCreation() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address token1 = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Token1",
            "TK1",
            "cid1",
            "img1",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        
        address token2 = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Token2", 
            "TK2",
            "cid2",
            "img2",
            3 days,
            false,
            0,
            0,
            200 ether
        );
        vm.stopPrank();

        IMineFun.MinedTokenView[] memory allTokens = tokenFactory.getAllMinedTokens();
        assertEq(allTokens.length, 2, "Should have 2 tokens");
        assertEq(allTokens[0].name, "Token1", "First token name should match");
        assertEq(allTokens[1].name, "Token2", "Second token name should match");
    }

    function test_GetContributionsForToken_ZeroInitially() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "cid",
            "img",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        uint256 contribution = tokenFactory.getContributionsForToken(minedTokenAddress, user1);
        assertEq(contribution, 0, "Initial contribution should be zero");
    }

    function test_GetContributionsForToken_AfterMining() public {
        mockSolo.mint(user1, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "cid",
            "img",
            3 days,
            false,
            0,
            0,
            100 ether
        );

        uint256 mineCost = tokenFactory.PRICE_PER_MINE();
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();

        uint256 contribution = tokenFactory.getContributionsForToken(minedTokenAddress, user1);
        assertEq(contribution, mineCost, "Contribution should match mining cost");
    }

    function test_GetAllContributionsForToken_MultipleUsers() public {
        mockSolo.mint(user1, 1000 ether);
        mockSolo.mint(user2, 1000 ether);
        
        vm.startPrank(user1);
        address minedTokenAddress = tokenFactory.createMinedToken{value: 0.0001 ether}(
            "Test Token",
            "TEST",
            "cid",
            "img",
            3 days,
            false,
            0,
            0,
            100 ether
        );
        vm.stopPrank();

        uint256 mineCost = tokenFactory.PRICE_PER_MINE();
        
        vm.startPrank(user1);
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();
        
        vm.startPrank(user2);
        tokenFactory.mineToken{value: mineCost}(minedTokenAddress);
        vm.stopPrank();

        address[] memory contributors = new address[](2);
        contributors[0] = user1;
        contributors[1] = user2;
        
        uint256[] memory contributions = tokenFactory.getAllContributionsForToken(minedTokenAddress, contributors);
        assertEq(contributions.length, 2, "Should have 2 contributions");
        assertEq(contributions[0], mineCost, "User1 contribution should match");
        assertEq(contributions[1], mineCost, "User2 contribution should match");
    }

    function test_GetMinedTokenDetails_Success() public {
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

        (
            string memory name,
            string memory symbol,
            string memory metadataCID,
            string memory tokenImageCID,
            uint256 fundingRaised,
            uint256 tokensBought,
            uint256 bondingDeadline,
            address tokenAddress,
            address creatorAddress,
            bool bonded
        ) = tokenFactory.getMinedTokenDetails(minedTokenAddress);

        assertEq(name, "Test Token", "Token name should match");
        assertEq(symbol, "TEST", "Token symbol should match");
        assertEq(metadataCID, "bafkreiculf5cd436llky7tglhftg5enqcqljxv2elv4kglcaopzsjvmv24", "Metadata CID should match");
        assertEq(tokenImageCID, "img://test.png", "Image CID should match");
        assertEq(fundingRaised, 0, "Initial funding should be zero");
        assertEq(tokensBought, 0, "Initial tokens bought should be zero");
        assertEq(bondingDeadline, block.timestamp + 3 days, "Bonding deadline should match");
        assertEq(tokenAddress, minedTokenAddress, "Token address should match");
        assertEq(creatorAddress, user1, "Creator should be user1");
        assertFalse(bonded, "Token should not be bonded initially");
    }
}