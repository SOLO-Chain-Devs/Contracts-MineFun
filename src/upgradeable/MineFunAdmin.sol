// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "./MineFunStorage.sol";

/**
 * @title MineFunAdmin
 * @dev Admin functionality for MineFun platform
 */
abstract contract MineFunAdmin is MineFunStorage, OwnableUpgradeable, UUPSUpgradeable {
    /**
     * @dev Updates the USDT address
     * @param _newAddress New USDT address
     */
    function updateUSDTAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid address");
        USDT = _newAddress;
    }

    /**
     * @dev Updates the router address and related factory
     * @param _newAddress New router address
     */
    function updateRouterAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid address");
        UNISWAP_V2_ROUTER = _newAddress;
        router = IUniswapV2Router01(_newAddress);
        UNISWAP_V2_FACTORY = router.factory();
    }

    /**
     * @dev Updates the team wallet address
     * @param _newTeamWallet New team wallet address
     */
    function updateTeamWallet(address _newTeamWallet) external onlyOwner {
        require(_newTeamWallet != address(0), "Invalid team wallet address");
        teamWallet = _newTeamWallet;
    }

    /**
     * @dev Function that authorizes an upgrade to a new implementation
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
