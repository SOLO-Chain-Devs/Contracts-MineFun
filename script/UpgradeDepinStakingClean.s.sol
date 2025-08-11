// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/MockDepinStaking.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UpgradeDepinStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address proxy = vm.envAddress("DEPIN_PROXY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        DepinStaking newImplementation = new DepinStaking();
        console.log("New DepinStaking implementation:", address(newImplementation));

        // Upgrade proxy directly (deployer is the admin)
        // For TransparentUpgradeableProxy, we need to call upgradeToAndCall through the admin
        // Since deployer is the admin, we can call it directly
        (bool success, ) = proxy.call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(newImplementation),
                bytes("")
            )
        );
        require(success, "Upgrade failed");

        // Update env file with new implementation address
        string memory envPath = ".env.depin";
        string memory content = string(
            abi.encodePacked(
                "DEPIN_PROXY_ADMIN=",
                _toHexString(deployer),
                "\n",
                "DEPIN_PROXY=",
                _toHexString(proxy),
                "\n",
                "DEPIN_IMPLEMENTATION=",
                _toHexString(address(newImplementation)),
                "\n"
            )
        );
        vm.writeFile(envPath, content);
        console2.log("Updated ", envPath);

        vm.stopBroadcast();
    }

    function _toHexString(address account) internal pure returns (string memory) {
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
}
