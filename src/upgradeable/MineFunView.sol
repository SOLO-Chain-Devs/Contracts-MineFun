// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MineFunCore.sol";

/**
 * @title MineFunView
 * @dev View functions for the MineFun platform
 */
abstract contract MineFunView is MineFunCore {
    /**
     * @dev Gets all mined tokens
     * @return Array of MinedTokenView structs
     */
    function getAllMinedTokens() public view override returns (MinedTokenView[] memory) {
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
                minedToken.metadataCID,
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

    /**
     * @dev Gets contribution amount for a user for a specific token
     * @param minedTokenAddress Address of the token
     * @param user Address of the user
     * @return Contribution amount
     */
    function getContributionsForToken(
        address minedTokenAddress,
        address user
    ) public view override returns (uint) {
        return
            addressToMinedTokenMapping[minedTokenAddress].contributions[user];
    }

    /**
     * @dev Gets contributions for multiple users for a token
     * @param minedTokenAddress Address of the token
     * @param contributors Array of contributor addresses
     * @return Array of contribution amounts
     */
    function getAllContributionsForToken(
        address minedTokenAddress,
        address[] memory contributors
    ) public view override returns (uint[] memory) {
        uint[] memory contributions = new uint[](contributors.length);
        for (uint i = 0; i < contributors.length; i++) {
            contributions[i] = addressToMinedTokenMapping[minedTokenAddress]
                .contributions[contributors[i]];
        }
        return contributions;
    }

    /**
     * @dev Gets detailed information about a mined token
     * @param minedTokenAddress Address of the token
     * returns Tuple containing all token details
     */
    function getMinedTokenDetails(
        address minedTokenAddress
    )
        public
        view
        override
        returns (
            string memory name,
            string memory symbol,
            string memory metadataCID,
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
            minedToken.metadataCID,
            minedToken.tokenImageUrl,
            minedToken.fundingRaised,
            minedToken.tokensBought,
            minedToken.bondingDeadline,
            minedToken.tokenAddress,
            minedToken.creatorAddress,
            minedToken.bonded
        );
    }
}
