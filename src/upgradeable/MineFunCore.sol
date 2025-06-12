// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../Token.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./MineFunAdmin.sol";
import "./IMineFun.sol";

/**
 * @title MineFunCore
 * @dev Core business logic for the MineFun platform
 */
abstract contract MineFunCore is MineFunAdmin, IMineFun {
    /*
     * @dev Creates a new mined token with the specified parameters
     * @param name Token name
     * @param symbol Token symbol
     * @param CIDLink Token CID Link
     * @param imageCID URL to token image
     * @param bondingTime Duration of bonding period in seconds
     * @return Address of the newly created token
     */

    address public soloTokenAddress;

    // Upper limit to avoid a too high of a paywall
    uint256 public constant upperLimitMinSoloHeldForTokenCreation = 1000000 ether;

    function setSoloTokenAddress(address newToken) public onlyOwner {
        soloTokenAddress = newToken;
    }

    function createMinedToken(
        string memory name,
        string memory symbol,
        string memory CIDLink,
        string memory imageCID,
        uint256 bondingTime,
        bool proxyCreation,
        uint256 timestampOverride,
        uint256 blockNumberOverride,
        uint256 soloRequiredToMine
    ) public payable override returns (address) {
        require(msg.value >= MINEDTOKEN_CREATION_FEE, "Insufficient creation fee");
        require(bondingTime >= 1 minutes && bondingTime <= 7 days, "Bonding time must be between 1 and 7 days");

        uint256 timestamp;
        uint256 blockNum;

        if (proxyCreation) {
            require(timestampOverride > 0, "Invalid timestamp");
            require(blockNumberOverride > 0, "Invalid block number");
            timestamp = timestampOverride;
            blockNum = blockNumberOverride;
        } else {
            timestamp = block.timestamp;
            blockNum = block.number;
        }

        // Generate a unique salt
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, msg.sender, timestamp, blockNum));

        // Get the contract bytecode
        bytes memory bytecode = abi.encodePacked(type(Token).creationCode, abi.encode(name, symbol, INIT_SUPPLY));

        address minedTokenAddress;

        // Deploy using CREATE2
        assembly {
            minedTokenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(minedTokenAddress)) { revert(0, 0) }
        }

        require(minedTokenAddress != address(0), "CREATE2 failed");

        MinedToken storage newMinedToken = addressToMinedTokenMapping[minedTokenAddress];
        newMinedToken.name = name;
        newMinedToken.symbol = symbol;
        newMinedToken.metadataCID = CIDLink;
        newMinedToken.tokenImageCID = imageCID;
        newMinedToken.fundingRaised = 0;
        newMinedToken.tokensBought = 0;
        newMinedToken.bondingDeadline = block.timestamp + bondingTime;
        newMinedToken.tokenAddress = minedTokenAddress;
        newMinedToken.creatorAddress = msg.sender;
        newMinedToken.bonded = false;
        newMinedToken.soloRequiredToMine = soloRequiredToMine;

        minedTokenAddresses.push(minedTokenAddress);

        // Create a MinedTokenView instance
        MinedTokenView memory minedTokenView = MinedTokenView({
            name: newMinedToken.name,
            symbol: newMinedToken.symbol,
            metadataCID: newMinedToken.metadataCID,
            tokenImageCID: newMinedToken.tokenImageCID,
            fundingRaised: newMinedToken.fundingRaised,
            tokensBought: newMinedToken.tokensBought,
            bondingDeadline: newMinedToken.bondingDeadline,
            tokenAddress: newMinedToken.tokenAddress,
            creatorAddress: newMinedToken.creatorAddress,
            bonded: newMinedToken.bonded
        });

        emit MinedTokenCreated(minedTokenAddress, minedTokenView);
        return minedTokenAddress;
    }

    function mineToken(address minedTokenAddress) public payable override {
        MinedToken storage listedToken = addressToMinedTokenMapping[minedTokenAddress];
        require(listedToken.tokenAddress != address(0), "Token not found");
        require(!listedToken.bonded, "Token already bonded");

        require(block.timestamp < listedToken.bondingDeadline, "Bonding period expired");

        require(soloTokenAddress != address(0), "Solo token address not set");

        uint256 userBal = IERC20(soloTokenAddress).balanceOf(msg.sender);

        require(
            userBal >= listedToken.soloRequiredToMine,
            "You must hold a certain amount of Solo token to be able to mine."
        );

        require(
            IERC20(minedTokenAddress).balanceOf(msg.sender) + TOKENS_PER_MINE <= MAX_PER_WALLET,
            "Maximum mine per wallet reached"
        );

        require(msg.value == PRICE_PER_MINE, "Incorrect ETH amount sent");

        uint256 ethForLiquidity = msg.value / 2;
        uint256 ethForTeam = msg.value - ethForLiquidity;
        teamFunds[minedTokenAddress] += ethForTeam;

        uint256 totalTokensAfterPurchase = listedToken.tokensBought + TOKENS_PER_MINE;
        require(totalTokensAfterPurchase <= INIT_SUPPLY, "Not enough tokens left");

        Token minedToken = Token(minedTokenAddress);
        listedToken.fundingRaised += ethForLiquidity;
        listedToken.tokensBought = totalTokensAfterPurchase;
        listedToken.contributions[msg.sender] += msg.value;

        minedToken.mint(msg.sender, TOKENS_PER_MINE);

        emit TokenMined(minedTokenAddress, msg.sender, TOKENS_PER_MINE);

        if (listedToken.fundingRaised >= MINEDTOKEN_FUNDING_GOAL) {
            _createLiquidityPool(minedTokenAddress);
            uint256 remainingTokens = MAX_SUPPLY - INIT_SUPPLY;
            minedToken.mint(address(this), remainingTokens);
            _provideLiquidity(minedTokenAddress, remainingTokens, listedToken.fundingRaised);
            listedToken.bonded = true;
            emit TokenBonded(minedTokenAddress, listedToken.fundingRaised);

            // Unlock the token for transfers
            minedToken.launchToken();
        }
    }

    function updateSoloRequiredToMine(address minedTokenAddress, uint256 newRequirement) external {
        MinedToken storage listedToken = addressToMinedTokenMapping[minedTokenAddress];
        require(listedToken.tokenAddress != address(0), "Token not found");
        require(msg.sender == listedToken.creatorAddress, "Not token creator");

        listedToken.soloRequiredToMine = newRequirement;
        emit SoloRequirementUpdated(minedTokenAddress, newRequirement);
    }

    /**
     * @dev Creates a liquidity pool for a mined token
     * @param memeTokenAddress Address of the token
     * @return Address of the created pair
     */
    function _createLiquidityPool(address memeTokenAddress) internal returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

        address pair = factory.createPair(memeTokenAddress, router.WETH());
        emit LiquidityPoolCreated(pair, memeTokenAddress);
        return pair;
    }

    /**
     * @dev Provides liquidity to a token's pool
     * @param minedTokenAddress Address of the token
     * @param tokenAmount Amount of tokens to provide
     * @param ethAmount Amount of ETH to provide
     * @return Amount of liquidity tokens received
     */
    function _provideLiquidity(address minedTokenAddress, uint256 tokenAmount, uint256 ethAmount)
        internal
        returns (uint256)
    {
        Token minedToken = Token(minedTokenAddress);
        minedToken.approve(UNISWAP_V2_ROUTER, tokenAmount);

        (,, uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            minedTokenAddress, tokenAmount, tokenAmount, ethAmount, address(this), block.timestamp
        );

        emit LiquidityProvided(minedTokenAddress, tokenAmount, ethAmount);
        return liquidity;
    }

    /**
     * @dev Refunds contributors if bonding deadline is passed and token is not bonded
     * @param minedTokenAddress Address of the token
     */
    function refundContributors(address minedTokenAddress) public override {
        MinedToken storage listedToken = addressToMinedTokenMapping[minedTokenAddress];
        require(block.timestamp > listedToken.bondingDeadline, "Bonding deadline not reached");
        require(!listedToken.bonded, "Token bonded, no refunds available");

        uint256 contribution = listedToken.contributions[msg.sender];
        require(contribution > 0, "No contribution found");

        Token minedToken = Token(minedTokenAddress);
        minedToken.launchToken();
        uint256 userTokens = (contribution / PRICE_PER_MINE) * TOKENS_PER_MINE;

        minedToken.burn(msg.sender, userTokens);
        listedToken.contributions[msg.sender] = 0;

        uint256 refundAmount = contribution;
        uint256 teamFundForToken = teamFunds[minedTokenAddress];
        if (teamFundForToken > 0) {
            teamFunds[minedTokenAddress] -= contribution / 2; // Remove team's portion too
            refundAmount = contribution;
        }

        payable(msg.sender).transfer(refundAmount);

        emit ContributionRefunded(minedTokenAddress, msg.sender, refundAmount);
    }

    /**
     * @dev Allows team to retrieve accumulated funds after token is bonded
     * @param minedTokenAddress Address of the token
     */
    function retrieveTeamFunds(address minedTokenAddress) public override {
        MinedToken storage listedToken = addressToMinedTokenMapping[minedTokenAddress];
        require(listedToken.bonded, "Token did not bond");
        require(msg.sender == teamWallet, "Not authorized");

        uint256 amount = teamFunds[minedTokenAddress];
        require(amount > 0, "No funds available");

        teamFunds[minedTokenAddress] = 0;
        payable(teamWallet).transfer(amount);
    }
}
