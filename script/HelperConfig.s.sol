//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //Constants
    uint8 public constant DECIMALS = 8;
    uint256 public constant INITIAL_PRICE = 2e18;

    // Struct
    struct NetworkConfig {
        address priceFeed;
    }

    // Variable
    NetworkConfig public networkConfig;

    // Constructor
    constructor() {
        if (block.chainid == 11155111) {
            networkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            networkConfig = getMainNetEthConfig();
        } else if (block.chainid == 31337) {
            networkConfig = getOrCreateAnvilEthCongif();
        }
    }

    // Functions
    //

    // returns the config for the given network
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaEthConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaEthConfig;
    }

    function getMainNetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainNetEthConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return mainNetEthConfig;
    }

    function getOrCreateAnvilEthCongif() public returns (NetworkConfig memory) {
        // check if price feed exists
        if (networkConfig.priceFeed == address(0)) {
            return networkConfig;
        }

        vm.startBroadcast();
        NetworkConfig memory anvilEthConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        vm.stopBroadcast();
        return anvilEthConfig;
    }
}
