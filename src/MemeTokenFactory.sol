// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Token.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";

contract MemeTokenFactory is Ownable {
    IUniswapV2Router01 public immutable router;

    struct MemeToken {
        string name;
        string symbol;
        string description;
        string tokenImageUrl;
        uint fundingRaised;
        uint tokensBought;
        address tokenAddress;
        address creatorAddress;
        bool bonded;
    }

    address[] public memeTokenAddresses;
    mapping(address => MemeToken) public addressToMemeTokenMapping;

    uint constant MEMETOKEN_CREATION_FEE = 0.0001 ether;
    uint constant MEMECOIN_FUNDING_GOAL = 6.5 ether;
    uint constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    uint constant INIT_SUPPLY = (80 * MAX_SUPPLY) / 100; // 800M tokens
    uint constant BASE_PRICE = 0.00000000185 ether;

    address constant UNISWAP_V2_FACTORY =
        0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
    address constant UNISWAP_V2_ROUTER =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant USDT = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

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
            0,
            memeTokenAddress,
            msg.sender,
            false
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

        // **Growth Multiplier**
        uint multiplier = 1;

        // **Scale supply fraction**
        uint scaledSupply = ((currentSupply * 1e18) / MAX_SUPPLY) * multiplier;

        // **Growth factor**
        uint growthFactor = 1e18 + scaledSupply;

        // **Price adjustment**
        uint adjustedPrice = (BASE_PRICE * growthFactor * 2) / 1e18;

        // ✅ **Final ETH required calculation (avoiding precision loss)**
        requiredEth = (adjustedPrice * tokenQty) / 1e18;

        return requiredEth;
    }

    function buyMemeToken(
        address memeTokenAddress,
        uint tokenQty // ✅ tokenQty is now in WEI
    ) public payable {
        MemeToken storage listedToken = addressToMemeTokenMapping[
            memeTokenAddress
        ];

        require(listedToken.tokenAddress != address(0), "Token not found");
        require(!listedToken.bonded, "Token already bonded");

        uint totalTokensAfterPurchase = listedToken.tokensBought + tokenQty;

        require(
            totalTokensAfterPurchase <= INIT_SUPPLY,
            "Not enough tokens left"
        );

        Token memeToken = Token(memeTokenAddress);
        uint requiredEth = getRequiredEthForPurchase(
            memeTokenAddress,
            tokenQty
        );
        require(msg.value == requiredEth, "Incorrect ETH amount sent");

        listedToken.fundingRaised += msg.value;
        listedToken.tokensBought = totalTokensAfterPurchase;

        // **✅ Liquidity Provision Logic: Only Happens When Funding Goal is Met**
        if (listedToken.fundingRaised >= MEMECOIN_FUNDING_GOAL) {
            if (!listedToken.bonded) {
                _createLiquidityPool(memeTokenAddress);

                // ✅ **Mint Remaining 200M Tokens**
                uint remainingTokens = MAX_SUPPLY - INIT_SUPPLY;
                memeToken.mint(address(this), remainingTokens);

                // ✅ **Add Liquidity Using Remaining Tokens + Raised ETH**
                _provideLiquidity(
                    memeTokenAddress,
                    remainingTokens,
                    listedToken.fundingRaised
                );

                //memeToken.renounceOwnership();
            }
            listedToken.bonded = true;
        }

        // ✅ **Mint tokens for the buyer**
        memeToken.mint(msg.sender, tokenQty);
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
        path[1] = USDT;

        uint[] memory amountsOut = router.getAmountsOut(_amount, path);
        return amountsOut[1] / 1e6;
    }
}
