// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/Vial.sol";

contract DeployLightProtocol is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        LightProtocol lightProtocol = new LightProtocol(tokenAddress);

        console.log("LightProtocol deployed to:", address(lightProtocol));

        vm.stopBroadcast();
    }
}
