// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MineFun.sol";

contract Botfun {
    function BotAttack(
        address _minefunContract,
        address _tokenContract,
        uint _loop
    ) public payable {
        uint valueToSend = .0002 ether * _loop;
        require(msg.value == valueToSend, "Incorrect Value Sent");
        for (uint i; i < _loop; i++) {
            MineFun(_minefunContract).mineToken{value: .0002 ether}(
                _tokenContract
            );
        }
    }
}
