//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {DeliveryService} from "../src/Delivery.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployDelivery is Script {
    function run() external returns (DeliveryService) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        DeliveryService deliveryService = new DeliveryService(ethUsdPriceFeed);
        vm.stopBroadcast();
        return deliveryService;
    }
}
