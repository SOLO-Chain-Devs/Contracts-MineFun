// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IMineFun
 * @dev Interface for the MineFun platform
 */
interface IMineFun {
    struct MinedTokenView {
        string name;
        string symbol;
        string metadataCID;
        string tokenImageCID;
        uint256 fundingRaised;
        uint256 tokensBought;
        uint256 bondingDeadline;
        address tokenAddress;
        address creatorAddress;
        bool bonded;
    }

    // EVENTS

    event SoloRequirementUpdated(address indexed tokenAddress, uint256 newRequirement);
    event MinedTokenCreated(address indexed tokenAddress, MinedTokenView data);
    event TokenMined(address indexed tokenAddress, address indexed miner, uint256 amount);
    event TokenBonded(address indexed tokenAddress, uint256 fundingRaised);
    event LiquidityPoolCreated(address indexed pairAddress, address indexed tokenAddress);
    event LiquidityProvided(address indexed tokenAddress, uint256 tokenAmount, uint256 ethAmount);
    event ContributionRefunded(address indexed tokenAddress, address indexed contributor, uint256 amount);

    // EXTERNAL FUNCTIONS
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
    ) external payable returns (address);

    function mineToken(address minedTokenAddress) external payable;

    function getAllMinedTokens() external view returns (MinedTokenView[] memory);

    function getContributionsForToken(address minedTokenAddress, address user) external view returns (uint256);

    function getAllContributionsForToken(address minedTokenAddress, address[] memory contributors)
        external
        view
        returns (uint256[] memory);

    function refundContributors(address minedTokenAddress) external;

    function getMinedTokenDetails(address minedTokenAddress)
        external
        view
        returns (
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
        );

    function retrieveTeamFunds(address minedTokenAddress) external;
}
