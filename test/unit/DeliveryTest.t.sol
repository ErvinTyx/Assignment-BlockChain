// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {DeployDelivery} from "../../script/DeployDelivery.s.sol";
import {DeliveryService} from "../../src/Delivery.sol";
import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DeliveryTest is Test {
    DeliveryService public delivery;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployDelivery deployDelivery = new DeployDelivery();
        delivery = deployDelivery.run();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testModificationLimit() public view {
        assert(delivery.getMinimumDelay() == 1 hours);
    }
}
