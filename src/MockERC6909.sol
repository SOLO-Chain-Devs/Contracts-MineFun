// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC6909} from "@openzeppelin/contracts/token/ERC6909/draft-ERC6909.sol";

contract MockERC6909 is ERC6909 {
    constructor() {
        _mint(msg.sender, 1, 1);
    }

    function mint(address _address, uint256 _tokenId, uint256 _amount) public {
        _mint(_address, _tokenId, _amount);
    }
}
