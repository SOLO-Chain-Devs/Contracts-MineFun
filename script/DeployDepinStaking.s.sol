// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/upgradeable/MineFun.sol";
import "../src/ERC6909.sol";
import "../src/MockDepinStaking.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployDepinStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("ADMIN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        DepinStaking implementation = new DepinStaking();
        console.log("DepinStaking implementation:", address(implementation));

        ProxyAdmin admin = new ProxyAdmin(owner);
        console.log("ProxyAdmin:", address(admin));

        bytes memory initData = abi.encodeWithSelector(DepinStaking.initialize.selector, owner);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(admin),
            initData
        );
        console.log("DepinStaking proxy:", address(proxy));

        // Optionally write addresses to an env file for reuse
        string memory envPath = ".env.depin";
        string memory content = string(
            abi.encodePacked(
                "DEPIN_PROXY_ADMIN=",
                _toHexString(address(admin)),
                "\n",
                "DEPIN_PROXY=",
                _toHexString(address(proxy)),
                "\n",
                "DEPIN_IMPLEMENTATION=",
                _toHexString(address(implementation)),
                "\n"
            )
        );
        vm.writeFile(envPath, content);
        console2.log("Wrote addresses to ", envPath);

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
