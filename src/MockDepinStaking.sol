// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockERC6909} from "./MockERC6909.sol";

contract DepinStaking {
    MockERC6909 public immutable token;

    // user => tokenId => staked amount
    mapping(address => mapping(uint256 => uint256)) public stakedBalance;

    // Tracks total staked across all tokenIds for quick checks
    mapping(address => uint256) private _totalStaked;

    event Staked(address indexed user, uint256 indexed tokenId, uint256 amount);
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 amount);

    constructor(address _token) {
        token = MockERC6909(_token);
    }

    function stake(uint256 tokenId, uint256 amount) external {
        require(amount > 0, "Cannot stake 0");

        // Transfer tokens from user to staking contract
        token.transferFrom(msg.sender, address(this), tokenId, amount);

        // Update staked balance
        stakedBalance[msg.sender][tokenId] += amount;
        _totalStaked[msg.sender] += amount;

        emit Staked(msg.sender, tokenId, amount);
    }

    function unstake(uint256 tokenId, uint256 amount) external {
        uint256 staked = stakedBalance[msg.sender][tokenId];
        require(amount > 0, "Cannot unstake 0");
        require(staked >= amount, "Not enough staked");

        // Update staked balance
        stakedBalance[msg.sender][tokenId] -= amount;
        _totalStaked[msg.sender] -= amount;

        // Transfer tokens back to user
        token.transfer(msg.sender, tokenId, amount);

        emit Unstaked(msg.sender, tokenId, amount);
    }

    function stakedOf(address user, uint256 tokenId) external view returns (uint256) {
        return stakedBalance[user][tokenId];
    }

    function isStaking(address user) external view returns (bool) {
        return _totalStaked[user] > 0;
    }
}