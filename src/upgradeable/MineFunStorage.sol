// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IMineFun.sol";

/**
 * @title MineFunStorage
 * @dev Storage variables and structs for MineFun platform
 */
abstract contract MineFunStorage is Initializable {
    IUniswapV2Router01 public router;
    address public teamWallet; // Team wallet address
    mapping(address => uint256) public teamFunds; // Tracks ETH allocated for team wallet per token

    struct MinedToken {
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
        uint256 soloRequiredToMine;
        mapping(address => uint256) contributions; // Tracks user ETH contributions
    }

    address[] public minedTokenAddresses;
    mapping(address => MinedToken) public addressToMinedTokenMapping;

    // Constants
    uint256 public constant MINEDTOKEN_CREATION_FEE = 0.0001 ether;
    uint256 public constant MINEDTOKEN_FUNDING_GOAL = 0.01 ether; // change on mainet
    uint256 public constant PRICE_PER_MINE = 0.0004 ether; // change on mainet
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant TOKENS_PER_MINE = 50_000 ether;
    uint256 public constant INIT_SUPPLY = (50 * MAX_SUPPLY) / 100; // 500M tokens
    uint256 public constant MAX_PER_WALLET = 10_000_000 ether;

    address public UNISWAP_V2_FACTORY;
    address public UNISWAP_V2_ROUTER;
    address public USDT;

    // Gap for future storage variables in upgrades
    uint256[50] private __gap;
}
