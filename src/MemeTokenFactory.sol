// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Token.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemeTokenFactory is Ownable {
    IUniswapV2Router01 public immutable router;

    struct MemeToken {
        string name;
        string symbol;
        string description;
        string tokenImageUrl;
        uint fundingRaised;
        address tokenAddress;
        address creatorAddress;
    }

    address[] public memeTokenAddresses;
    mapping(address => MemeToken) public addressToMemeTokenMapping;

    uint constant MEMETOKEN_CREATION_FEE = 0.0001 ether;
    uint constant MEMECOIN_FUNDING_GOAL = 10 ether;
    uint constant MAX_SUPPLY = 1_000_000 * 1e18;
    uint constant INIT_SUPPLY = (20 * MAX_SUPPLY) / 100;
    uint constant BASE_PRICE = 0.00001 ether;
    uint constant GROWTH_RATE = 0.0000001 ether;

    address constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor() Ownable(msg.sender) {
        router = IUniswapV2Router01(UNISWAP_V2_ROUTER);
    }

    function createMemeToken(
        string memory name,
        string memory symbol,
        string memory imageUrl,
        string memory description
    ) public payable returns (address) {
        require(
            msg.value >= MEMETOKEN_CREATION_FEE,
            "Insufficient creation fee"
        );

        Token newToken = new Token(name, symbol, INIT_SUPPLY);
        address memeTokenAddress = address(newToken);

        MemeToken memory newMemeToken = MemeToken(
            name,
            symbol,
            description,
            imageUrl,
            0,
            memeTokenAddress,
            msg.sender
        );
        memeTokenAddresses.push(memeTokenAddress);
        addressToMemeTokenMapping[memeTokenAddress] = newMemeToken;

        return memeTokenAddress;
    }

    function getRequiredEthForPurchase(
        address memeTokenAddress,
        uint tokenQty
    ) public view returns (uint requiredEth) {
        require(
            addressToMemeTokenMapping[memeTokenAddress].tokenAddress !=
                address(0),
            "Token not found"
        );

        // Fetch the current supply of the token
        uint currentSupply = Token(memeTokenAddress).totalSupply();

        // **Increase the growth multiplier** (Try different values: 2, 5, 10)
        uint multiplier = 5;

        // Scale the supply fraction to make price rise more quickly
        uint scaledSupply = ((currentSupply * 1e18) / MAX_SUPPLY) * multiplier;

        // **Make the growth factor more aggressive**
        uint growthFactor = (1e18 + scaledSupply); // 1 + (scaledSupply * multiplier)

        // **Increase BASE_PRICE for a stronger effect**
        uint adjustedPrice = (BASE_PRICE * growthFactor * 2) / 1e18; // Doubling for higher growth

        // Final cost is the adjusted price multiplied by token quantity
        requiredEth = adjustedPrice * tokenQty;

        return requiredEth;
    }

    function buyMemeToken(
        address memeTokenAddress,
        uint tokenQty
    ) public payable {
        require(
            addressToMemeTokenMapping[memeTokenAddress].tokenAddress !=
                address(0),
            "Token not found"
        );
        uint requiredEth = getRequiredEthForPurchase(
            memeTokenAddress,
            tokenQty
        );
        require(msg.value >= requiredEth, "Incorrect ETH sent");

        MemeToken storage listedToken = addressToMemeTokenMapping[
            memeTokenAddress
        ];
        Token memeToken = Token(memeTokenAddress);

        require(
            listedToken.fundingRaised < MEMECOIN_FUNDING_GOAL,
            "Funding goal reached"
        );
        listedToken.fundingRaised += msg.value;

        if (listedToken.fundingRaised >= MEMECOIN_FUNDING_GOAL) {
            _createLiquidityPool(memeTokenAddress);
        }

        memeToken.mint(tokenQty * 1e18, msg.sender);
    }

    function sellMemeToken(address memeTokenAddress, uint tokenQty) public {
        require(
            addressToMemeTokenMapping[memeTokenAddress].tokenAddress !=
                address(0),
            "Token not found"
        );
        Token memeToken = Token(memeTokenAddress);
        uint ethAmount = getRequiredEthForPurchase(memeTokenAddress, tokenQty);
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH in contract"
        );

        memeToken.burn(msg.sender, tokenQty * 1e18);
        payable(msg.sender).transfer(ethAmount);
    }

    function _createLiquidityPool(
        address memeTokenAddress
    ) internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

        address pair = factory.createPair(memeTokenAddress, router.WETH());
        return pair;
    }

    function _provideLiquidity(
        address memeTokenAddress,
        uint tokenAmount,
        uint ethAmount
    ) internal returns (uint) {
        Token memeToken = Token(memeTokenAddress);
        memeToken.approve(UNISWAP_V2_ROUTER, tokenAmount);

        (, , uint liquidity) = router.addLiquidityETH{value: ethAmount}(
            memeTokenAddress,
            tokenAmount,
            tokenAmount,
            ethAmount,
            address(this),
            block.timestamp
        );
        return liquidity;
    }

    function getAllMemeTokens() public view returns (MemeToken[] memory) {
        MemeToken[] memory allTokens = new MemeToken[](
            memeTokenAddresses.length
        );
        for (uint i = 0; i < memeTokenAddresses.length; i++) {
            allTokens[i] = addressToMemeTokenMapping[memeTokenAddresses[i]];
        }
        return allTokens;
    }

    function getUSDValue(uint256 _amount) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

        uint[] memory amountsOut = router.getAmountsOut(_amount, path);
        return amountsOut[1]/1e6;
    }
}
