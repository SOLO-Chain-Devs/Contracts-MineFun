// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";

contract Token is ERC20, Ownable {
    bool launched;

    event Launched(uint256 timestamp);

    constructor(
        string memory name,
        string memory symbol,
        uint initialMintValue
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialMintValue);
    }

    function mint(
        address receiver,
        uint mintQty
    ) external onlyOwner returns (uint) {
        _mint(receiver, mintQty);
        return 1;
    }

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        if (!launched) {
            require(
                from == address(0) || from == owner(),
                "Cannot transfer tokens until bonding is complete"
            );
        }

        super._update(from, to, value);
    }

    function launchToken() public onlyOwner {
        launched = true;
        emit Launched(block.timestamp);
    }
}
