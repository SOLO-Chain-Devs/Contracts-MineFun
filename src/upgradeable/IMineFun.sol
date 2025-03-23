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
        uint fundingRaised;
        uint tokensBought;
        uint bondingDeadline;
        address tokenAddress;
        address creatorAddress;
        bool bonded;
    }

    // EVENTS
    event MinedTokenCreated(address indexed tokenAddress, MinedTokenView data);
    event TokenMined(
        address indexed tokenAddress,
        address indexed miner,
        uint amount
    );
    event TokenBonded(address indexed tokenAddress, uint256 fundingRaised);
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

    // EXTERNAL FUNCTIONS
    function createMinedToken(
        string memory name,
        string memory symbol,
        string memory CIDLink,
        uint bondingTime,
        bool proxyCreation,
        uint timestampOverride,
        uint blockNumberOverride
    ) external payable returns (address);

    function mineToken(address minedTokenAddress) external payable;

    function getAllMinedTokens() external view returns (MinedTokenView[] memory);

    function getContributionsForToken(
        address minedTokenAddress,
        address user
    ) external view returns (uint);

    function getAllContributionsForToken(
        address minedTokenAddress,
        address[] memory contributors
    ) external view returns (uint[] memory);

    function refundContributors(address minedTokenAddress) external;

    function getMinedTokenDetails(
        address minedTokenAddress
    )
        external
        view
        returns (
            string memory name,
            string memory symbol,
            string memory metadataCID,
            uint fundingRaised,
            uint tokensBought,
            uint bondingDeadline,
            address tokenAddress,
            address creatorAddress,
            bool bonded
        );

    function retrieveTeamFunds(address minedTokenAddress) external;
}
