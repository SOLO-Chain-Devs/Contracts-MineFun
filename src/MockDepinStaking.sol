// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC6909} from "@openzeppelin/contracts/token/ERC6909/draft-ERC6909.sol";

contract DepinStaking {
    //mapping(address=> bool) public isAcceptedToken;

    // user => tokenAddress => tokenId => staked amount
    mapping(address => mapping(address => mapping(uint256 => uint256))) public stakedBalance;

    // Tracks total staked across all tokenIds for quick checks
    mapping(address => uint256) private _totalStaked;

    event Staked(address indexed user, address indexed token, uint256 indexed tokenId, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 indexed tokenId, uint256 amount);

    constructor() {    }

    /* function updateAcceptedToken(address token, bool _isAccepted) public {
        isAcceptedToken[token] = _isAccepted;
    }

    function isAccepted(address token) public view returns (bool) {
        return isAcceptedToken[token];
    } */

    function stake(address _token, uint256 _tokenId, uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
       // require(isAcceptedToken[_token], "Token not accepted");

        // Update staked balance
        stakedBalance[msg.sender][_token][_tokenId] += _amount;
        _totalStaked[msg.sender] += _amount;

        // Transfer tokens from user to staking contract
        bool success = ERC6909(_token).transferFrom(msg.sender, address(this), _tokenId, _amount);
        require(success, "Transfer failed");

        emit Staked(msg.sender, _token, _tokenId, _amount);
    }

    function unstake(address _token, uint256 _tokenId, uint256 _amount) external {
        uint256 staked = stakedBalance[msg.sender][_token][_tokenId];
        require(_amount > 0, "Cannot unstake 0");
        require(staked >= _amount, "Not enough staked");

        // Update staked balance
        stakedBalance[msg.sender][_token][_tokenId] -= _amount;
        _totalStaked[msg.sender] -= _amount;

        // Transfer tokens back to user
        bool success = ERC6909(_token).transfer(msg.sender, _tokenId, _amount);
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, _token, _tokenId, _amount);
    }

    function stakedOf(address user, address token, uint256 tokenId) external view returns (uint256) {
        return stakedBalance[user][token][tokenId];
    }

    function isStaking(address user) external view returns (bool) {
        return _totalStaked[user] > 0;
    }
}