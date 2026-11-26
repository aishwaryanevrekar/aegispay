// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MockTUSD8} from "../src/mocks/MockTUSD8.sol";
import {MockIdentityRegistry} from "../src/mocks/MockIdentityRegistry.sol";
import {MockReputationRegistry} from "../src/mocks/MockReputationRegistry.sol";
import {PaymentRouter} from "../src/PaymentRouter.sol";
import {AegisFactory} from "../src/AegisFactory.sol";

/// @notice Deploy the AegisPay stack. On chain 44005 uses the official tUSD8;
///         locally it deploys a mock stablecoin so `anvil` demos work offline.
contract Deploy is Script {
    address internal constant TUSD8_AEVUM = 0x456569838f1d43009A91ebA4263147Afd7233483;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        address token = block.chainid == 44005 ? TUSD8_AEVUM : address(new MockTUSD8());
        MockIdentityRegistry identity = new MockIdentityRegistry();
        MockReputationRegistry reputation = new MockReputationRegistry();
        PaymentRouter router = new PaymentRouter(token, address(reputation), address(identity));
        AegisFactory factory = new AegisFactory(token, address(identity), address(reputation), address(router));

        vm.stopBroadcast();

        console2.log("=== AegisPay deployment ===");
        console2.log("chainId      :", block.chainid);
        console2.log("tUSD8        :", token);
        console2.log("identity     :", address(identity));
        console2.log("reputation   :", address(reputation));
        console2.log("router       :", address(router));
        console2.log("factory      :", address(factory));

        string memory out = string.concat(
            "chainId=", vm.toString(block.chainid),
            "\nTUSD8_ADDRESS=", vm.toString(token),
            "\nIDENTITY_REGISTRY_ADDRESS=", vm.toString(address(identity)),
            "\nREPUTATION_REGISTRY_ADDRESS=", vm.toString(address(reputation)),
            "\nPAYMENT_ROUTER_ADDRESS=", vm.toString(address(router)),
            "\nAEGIS_FACTORY_ADDRESS=", vm.toString(address(factory)),
            "\n"
        );
        vm.createDir("deployments", true);
        vm.writeFile(string.concat("deployments/", vm.toString(block.chainid), ".txt"), out);
    }
}
