// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint initialMintValue
    ) ERC20(name, symbol) Ownable(msg.sender) {
       // transferOwnership(msg.sender);
        _mint(msg.sender, initialMintValue);
    }

    function mint(
        address receiver,
        uint mintQty
    ) external onlyOwner() returns (uint) {
        _mint(receiver, mintQty);
        return 1;
    }

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }
}
