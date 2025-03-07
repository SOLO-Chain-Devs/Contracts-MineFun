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
    function initialize(address _teamWallet) public initializer {
        require(_teamWallet != address(0), "Invalid team wallet");
        
        teamWallet = _teamWallet;
        UNISWAP_V2_ROUTER = 0x029bE7FB61D3E60c1876F1E0B44506a7108d3c70;
        UNISWAP_V2_FACTORY = 0xB2c5B17bF7A655B0FC3Eb44038E8A65EEa904407;
        USDT = 0xdAa055658ab05B9e1d3c4a4827a88C25F51032B3;
        router = IUniswapV2Router01(UNISWAP_V2_ROUTER);
        
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }
}
