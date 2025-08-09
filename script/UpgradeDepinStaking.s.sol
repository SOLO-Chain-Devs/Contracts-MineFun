// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MockDepinStaking.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "forge-std/console2.sol";

contract UpgradeDepinStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAdmin = vm.envAddress("DEPIN_PROXY_ADMIN");
        address proxy = vm.envAddress("DEPIN_PROXY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        DepinStaking newImplementation = new DepinStaking();
        console.log("New DepinStaking implementation:", address(newImplementation));

        // Upgrade via ProxyAdmin (OZ v5 requires upgradeAndCall)
        ProxyAdmin(payable(proxyAdmin)).upgradeAndCall{
            value: 0
        }(
            ITransparentUpgradeableProxy(payable(proxy)),
            address(newImplementation),
            bytes("")
        );

        // Update env file with new implementation address
        string memory envPath = ".env.depin";
        string memory existing = vm.readFile(envPath);
        // naive replace DEPIN_IMPLEMENTATION line
        string memory newLine = string(abi.encodePacked("DEPIN_IMPLEMENTATION=", _toHexString(address(newImplementation)), "\n"));
        // If file didn't exist, existing will revert; wrap in try-catch equivalent not available. We'll just overwrite.
        string memory content = string(abi.encodePacked("DEPIN_PROXY_ADMIN=", _toHexString(proxyAdmin), "\n","DEPIN_PROXY=", _toHexString(proxy), "\n", newLine));
        vm.writeFile(envPath, content);
        console2.log("Updated ", envPath);

        vm.stopBroadcast();
    }
}

function _toHexString(address account) pure returns (string memory) {
    bytes20 data = bytes20(account);
    bytes16 hexSymbols = 0x30313233343536373839616263646566; // 0-9 a-f
    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < 20; i++) {
        uint8 b = uint8(data[i]);
        str[2 + i * 2] = bytes1(hexSymbols[b >> 4]);
        str[3 + i * 2] = bytes1(hexSymbols[b & 0x0f]);
    }
    return string(str);
}


