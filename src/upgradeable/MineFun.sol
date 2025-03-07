// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MineFunView.sol";

/**
 * @title MineFun
 * @dev Implementation contract for the MineFun platform
 * @notice This contract allows users to create and mine tokens with automated liquidity pool creation
 */
contract MineFun is MineFunView {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with required parameters
     * @param _teamWallet Team wallet address for receiving funds
     */
    function initialize(address _teamWallet, address _uniswapV2Router, address _uniswapV2Factory, address _usdt) public initializer {
        require(_teamWallet != address(0), "Invalid team wallet");
        
        teamWallet = _teamWallet;
        UNISWAP_V2_ROUTER = _uniswapV2Router;
        UNISWAP_V2_FACTORY = _uniswapV2Factory;
        USDT = _usdt;
        router = IUniswapV2Router01(UNISWAP_V2_ROUTER);
        
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }
}
