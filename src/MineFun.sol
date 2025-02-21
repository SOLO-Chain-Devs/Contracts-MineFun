// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Token.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";

contract MineFun is Ownable {
    IUniswapV2Router01 public immutable router;
    address public immutable teamWallet; // Team wallet address
    mapping(address => uint) public teamFunds; // Tracks ETH allocated for team wallet per token
    struct MinedToken {
        string name;
        string symbol;
        string description;
        string tokenImageUrl;
        uint fundingRaised;
        uint tokensBought;
        uint bondingDeadline;
        address tokenAddress;
        address creatorAddress;
        bool bonded;
        mapping(address => uint) contributions; // Tracks user ETH contributions
    }

    struct MinedTokenView {
        string name;
        string symbol;
        string description;
        string tokenImageUrl;
        uint fundingRaised;
        uint tokensBought;
        uint bondingDeadline;
        address tokenAddress;
        address creatorAddress;
        bool bonded;
    }

    address[] public minedTokenAddresses;
    mapping(address => MinedToken) public addressToMinedTokenMapping;

    uint constant MINEDTOKEN_CREATION_FEE = 0.0001 ether;
    uint constant MINEDTOKEN_FUNDING_GOAL = 1 ether;
    uint constant PRICE_PER_MINE = 0.0002 ether;
    uint constant MAX_SUPPLY = 1_000_000_000 ether;
    uint constant TOKENS_PER_MINE = 50_000 ether;
    uint constant INIT_SUPPLY = (50 * MAX_SUPPLY) / 100; // 500M tokens
    uint constant MAX_PER_WALLET = 10_000_000 ether;

    address public constant UNISWAP_V2_FACTORY =
        0xB2c5B17bF7A655B0FC3Eb44038E8A65EEa904407;
    address public constant UNISWAP_V2_ROUTER =
        0x029bE7FB61D3E60c1876F1E0B44506a7108d3c70;

    address public constant USDT = 0xdAa055658ab05B9e1d3c4a4827a88C25F51032B3;

    // ✅ EVENTS
    event MinedTokenCreated(address indexed tokenAddress,MinedTokenView data);
    event TokenMined(
        address indexed tokenAddress,
        address indexed miner,
        uint amount
    );
    event TokenBonded(
        address indexed tokenAddress,
        uint256 fundingRaised
    );
    event LiquidityPoolCreated(
        address indexed pairAddress,
        address indexed tokenAddress
    );
    event LiquidityProvided(
        address indexed tokenAddress,
        uint tokenAmount,
        uint ethAmount
    );
    event ContributionRefunded(
        address indexed tokenAddress,
        address indexed contributor,
        uint amount
    );

    constructor(address _teamWallet) Ownable(msg.sender) {
        router = IUniswapV2Router01(UNISWAP_V2_ROUTER);
        require(_teamWallet != address(0), "Invalid team wallet");
        teamWallet = _teamWallet;
    }

    function createMinedToken(
        string memory name,
        string memory symbol,
        string memory imageUrl,
        string memory description,
        uint bondingTime
    ) public payable returns (address) {
        require(
            msg.value >= MINEDTOKEN_CREATION_FEE,
            "Insufficient creation fee"
        );
        require(
            bondingTime >= 1 minutes && bondingTime <= 7 days,
            "Bonding time must be between 1 and 7 days"
        );

        Token newToken = new Token(name, symbol, INIT_SUPPLY);
        address minedTokenAddress = address(newToken);

        MinedToken storage newMinedToken = addressToMinedTokenMapping[
            minedTokenAddress
        ];
        newMinedToken.name = name;
        newMinedToken.symbol = symbol;
        newMinedToken.description = description;
        newMinedToken.tokenImageUrl = imageUrl;
        newMinedToken.fundingRaised = 0;
        newMinedToken.tokensBought = 0;
        newMinedToken.bondingDeadline = block.timestamp + bondingTime;
        newMinedToken.tokenAddress = minedTokenAddress;
        newMinedToken.creatorAddress = msg.sender;
        newMinedToken.bonded = false;

        minedTokenAddresses.push(minedTokenAddress);

        // Create a MinedTokenView instance
        MinedTokenView memory minedTokenView = MinedTokenView({
            name: newMinedToken.name,
            symbol: newMinedToken.symbol,
            description: newMinedToken.description,
            tokenImageUrl: newMinedToken.tokenImageUrl,
            fundingRaised: newMinedToken.fundingRaised,
            tokensBought: newMinedToken.tokensBought,
            bondingDeadline: newMinedToken.bondingDeadline,
            tokenAddress: newMinedToken.tokenAddress,
            creatorAddress: newMinedToken.creatorAddress,
            bonded: newMinedToken.bonded
        });

        emit MinedTokenCreated(minedTokenAddress,minedTokenView);
        return minedTokenAddress;
    }

    function mineToken(address minedTokenAddress) public payable {
        MinedToken storage listedToken = addressToMinedTokenMapping[
            minedTokenAddress
        ];
        require(listedToken.tokenAddress != address(0), "Token not found");
        require(!listedToken.bonded, "Token already bonded");
        require(
            block.timestamp < listedToken.bondingDeadline,
            "Bonding period expired"
        );
        require(
            IERC20(minedTokenAddress).balanceOf(msg.sender) + TOKENS_PER_MINE <=
                MAX_PER_WALLET,
            "Maximum mine per wallet reached"
        );
        require(msg.value == PRICE_PER_MINE, "Incorrect ETH amount sent");

        uint ethForLiquidity = msg.value / 2;
        uint ethForTeam = msg.value - ethForLiquidity;
        teamFunds[minedTokenAddress] += ethForTeam;

        uint totalTokensAfterPurchase = listedToken.tokensBought +
            TOKENS_PER_MINE;
        require(
            totalTokensAfterPurchase <= INIT_SUPPLY,
            "Not enough tokens left"
        );

        Token minedToken = Token(minedTokenAddress);
        listedToken.fundingRaised += ethForLiquidity;
        listedToken.tokensBought = totalTokensAfterPurchase;
        listedToken.contributions[msg.sender] += msg.value;

        minedToken.mint(msg.sender, TOKENS_PER_MINE);

        emit TokenMined(minedTokenAddress, msg.sender, TOKENS_PER_MINE);

        if (listedToken.fundingRaised >= MINEDTOKEN_FUNDING_GOAL) {
            _createLiquidityPool(minedTokenAddress);
            uint remainingTokens = MAX_SUPPLY - INIT_SUPPLY;
            minedToken.mint(address(this), remainingTokens);
            _provideLiquidity(
                minedTokenAddress,
                remainingTokens,
                listedToken.fundingRaised
            );
            listedToken.bonded = true;
            emit TokenBonded(minedTokenAddress,listedToken.fundingRaised);

            // ✅ Unlock the token for transfers
            minedToken.launchToken();
        }
    }

    function _createLiquidityPool(
        address memeTokenAddress
    ) internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

        address pair = factory.createPair(memeTokenAddress, router.WETH());
        emit LiquidityPoolCreated(pair, memeTokenAddress);
        return pair;
    }

    function _provideLiquidity(
        address minedTokenAddress,
        uint tokenAmount,
        uint ethAmount
    ) internal returns (uint) {
        Token minedToken = Token(minedTokenAddress);
        minedToken.approve(UNISWAP_V2_ROUTER, tokenAmount);

        (, , uint liquidity) = router.addLiquidityETH{value: ethAmount}(
            minedTokenAddress,
            tokenAmount,
            tokenAmount,
            ethAmount,
            address(this),
            block.timestamp
        );

        emit LiquidityProvided(minedTokenAddress, tokenAmount, ethAmount);
        return liquidity;
    }

    function getAllMinedTokens() public view returns (MinedTokenView[] memory) {
        MinedTokenView[] memory allTokens = new MinedTokenView[](
            minedTokenAddresses.length
        );
        for (uint i = 0; i < minedTokenAddresses.length; i++) {
            MinedToken storage minedToken = addressToMinedTokenMapping[
                minedTokenAddresses[i]
            ];
            allTokens[i] = MinedTokenView(
                minedToken.name,
                minedToken.symbol,
                minedToken.description,
                minedToken.tokenImageUrl,
                minedToken.fundingRaised,
                minedToken.tokensBought,
                minedToken.bondingDeadline,
                minedToken.tokenAddress,
                minedToken.creatorAddress,
                minedToken.bonded
            );
        }
        return allTokens;
    }

    function getContributionsForToken(
        address minedTokenAddress,
        address user
    ) public view returns (uint) {
        return
            addressToMinedTokenMapping[minedTokenAddress].contributions[user];
    }

    function getAllContributionsForToken(
        address minedTokenAddress,
        address[] memory contributors
    ) public view returns (uint[] memory) {
        uint[] memory contributions = new uint[](contributors.length);
        for (uint i = 0; i < contributors.length; i++) {
            contributions[i] = addressToMinedTokenMapping[minedTokenAddress]
                .contributions[contributors[i]];
        }
        return contributions;
    }

    function getUSDValue(uint256 _amount) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = USDT;

        uint[] memory amountsOut = router.getAmountsOut(_amount, path);
        return amountsOut[1] / 1e6;
    }

    function refundContributors(address minedTokenAddress) public {
        MinedToken storage listedToken = addressToMinedTokenMapping[
            minedTokenAddress
        ];
        require(
            block.timestamp > listedToken.bondingDeadline,
            "Bonding deadline not reached"
        );
        require(!listedToken.bonded, "Token bonded, no refunds available");

        uint contribution = listedToken.contributions[msg.sender];
        require(contribution > 0, "No contribution found");

        Token minedToken = Token(minedTokenAddress);
        minedToken.launchToken();
        uint userTokens = (contribution / PRICE_PER_MINE) * TOKENS_PER_MINE;

        minedToken.burn(msg.sender, userTokens);
        listedToken.contributions[msg.sender] = 0;

        uint refundAmount = contribution;
        uint teamFundForToken = teamFunds[minedTokenAddress];
        if (teamFundForToken > 0) {
            teamFunds[minedTokenAddress] -= contribution / 2; // Remove team’s portion too
            refundAmount = contribution;
        }

        payable(msg.sender).transfer(refundAmount);

        emit ContributionRefunded(minedTokenAddress, msg.sender, refundAmount);
    }

    function getMinedTokenDetails(
        address minedTokenAddress
    )
        public
        view
        returns (
            string memory name,
            string memory symbol,
            string memory description,
            string memory tokenImageUrl,
            uint fundingRaised,
            uint tokensBought,
            uint bondingDeadline,
            address tokenAddress,
            address creatorAddress,
            bool bonded
        )
    {
        MinedToken storage minedToken = addressToMinedTokenMapping[
            minedTokenAddress
        ];

        return (
            minedToken.name,
            minedToken.symbol,
            minedToken.description,
            minedToken.tokenImageUrl,
            minedToken.fundingRaised,
            minedToken.tokensBought,
            minedToken.bondingDeadline,
            minedToken.tokenAddress,
            minedToken.creatorAddress,
            minedToken.bonded
        );
    }

    function retrieveTeamFunds(address minedTokenAddress) public {
        MinedToken storage listedToken = addressToMinedTokenMapping[
            minedTokenAddress
        ];
        require(listedToken.bonded, "Token did not bond");
        require(msg.sender == teamWallet, "Not authorized");

        uint amount = teamFunds[minedTokenAddress];
        require(amount > 0, "No funds available");

        teamFunds[minedTokenAddress] = 0;
        payable(teamWallet).transfer(amount);
    }
}
