// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IERC6909
 * @dev Interface for ERC6909 Multi-Token Standard
 * @notice EIP-6909 Compliant Interface
 */
interface IERC6909 {
    event Transfer(
        address caller, address indexed sender, address indexed receiver, uint256 indexed id, uint256 amount
    );
    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function allowance(address owner, address spender, uint256 id) external view returns (uint256);
    function isOperator(address owner, address spender) external view returns (bool);
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);
    function setOperator(address spender, bool approved) external returns (bool);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @title ERC6909
 * @dev Implementation of the ERC6909 Multi-Token Standard
 * @notice EIP-6909 Compliant Implementation
 */
contract ERC6909 is IERC6909 {
    /// @dev Thrown when owner balance for id is insufficient.
    error InsufficientBalance(address owner, uint256 id);

    /// @dev Thrown when spender allowance for id is insufficient.
    error InsufficientPermission(address spender, uint256 id);

    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public allowance;
    mapping(address => mapping(address => bool)) public isOperator;
    mapping(uint256 => uint256) public totalSupply;

    // URI support for metadata
    mapping(uint256 => string) private _tokenURIs;
    string private _baseURI;

    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool) {
        if (balanceOf[msg.sender][id] < amount) revert InsufficientBalance(msg.sender, id);
        balanceOf[msg.sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, msg.sender, receiver, id, amount);
        return true;
    }

    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool) {
        if (sender != msg.sender && !isOperator[sender][msg.sender]) {
            uint256 senderAllowance = allowance[sender][msg.sender][id];
            if (senderAllowance < amount) revert InsufficientPermission(msg.sender, id);
            if (senderAllowance != type(uint256).max) {
                allowance[sender][msg.sender][id] = senderAllowance - amount;
            }
        }

        if (balanceOf[sender][id] < amount) revert InsufficientBalance(sender, id);
        balanceOf[sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, sender, receiver, id, amount);
        return true;
    }

    function approve(address spender, uint256 id, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender][id] = amount;
        emit Approval(msg.sender, spender, id, amount);
        return true;
    }

    function setOperator(address spender, bool approved) external returns (bool) {
        isOperator[msg.sender][spender] = approved;
        emit OperatorSet(msg.sender, spender, approved);
        return true;
    }

    /// @notice Checks if a contract implements an interface.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x0f632fb3 || interfaceId == 0x01ffc9a7; // ERC6909 + ERC165
    }

    function _mint(address receiver, uint256 id, uint256 amount) internal {
        balanceOf[receiver][id] += amount;
        totalSupply[id] += amount;
        emit Transfer(msg.sender, address(0), receiver, id, amount);
    }

    function _burn(address sender, uint256 id, uint256 amount) internal {
        balanceOf[sender][id] -= amount;
        totalSupply[id] -= amount;
        emit Transfer(msg.sender, sender, address(0), id, amount);
    }

    // URI functions for metadata support
    function tokenURI(uint256 id) external view returns (string memory) {
        string memory _tokenURI = _tokenURIs[id];

        // If token has specific URI, return it
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // Otherwise return baseURI + id
        if (bytes(_baseURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _toString(id)));
        }

        return "";
    }

    function _setTokenURI(uint256 id, string memory uri) internal {
        _tokenURIs[id] = uri;
    }

    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}



