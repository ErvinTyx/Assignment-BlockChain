// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployDelivery} from "../../script/DeployDelivery.s.sol";
import {DeliveryService} from "../../src/Delivery.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract InteractionTest is Test {
    DeliveryService public delivery;
    HelperConfig public helperConfig;

    event DeliveryScheduled(
        uint256 deliveryID,
        address indexed customer,
        string fromAddress,
        string toAddress,
        uint256 price,
        uint256 payAmount,
        uint256 scheduledTime
    );
    event DeliveryModified(uint256 deliveryID, uint256 newScheduledTime, uint256 remainingAttempts);
    event DeliveryCancelled(uint256 deliveryID, address indexed customer);
    event DeliveryCompleted(uint256 deliveryID, address indexed customer);
    event DeliveryDelivered(uint256 deliveryID);
    event OutForDelivery(uint256 deliveryID);

    string public constant FROM_ADDRESS = "PJ";
    string public constant TO_ADDRESS = "Seremban";
    uint256 public deliveryID;
    uint256 public newTimestamp;
    // Constants
    uint256 public constant MIN_DELAY = 1 hours; // Minimum scheduling delay
    uint256 public constant MODIFICATION_LIMIT = 3;
    uint256 public constant COOLING_PERIOD = 30 days;
    uint256 public constant CANCELLATION_LIMIT = 3;
    uint256 public constant SEND_VALUE = 5 ether;
    uint256 public constant PRICE = 5e8;
    uint256 public constant STARTING_BALANCE = 10 ether;
    address public CUSTOMER = makeAddr("customer");

    function setUp() external {
        DeployDelivery deployDelivery = new DeployDelivery();
        delivery = deployDelivery.run();
        vm.deal(CUSTOMER, STARTING_BALANCE);
    }

    function testUserOrderCompleted() public {
        vm.prank(CUSTOMER);
        newTimestamp = 3 hours;
        deliveryID = delivery.scheduleDelivery{value: SEND_VALUE}(FROM_ADDRESS, TO_ADDRESS, PRICE, newTimestamp);

        assert(delivery.getDelivery(deliveryID).status == DeliveryService.StatusDelivery.Scheduled);

        vm.warp(4 hours);
        vm.roll(block.number + 1);
        vm.prank(delivery.getOwner());
        delivery.outFordelivery(deliveryID);
        vm.prank(delivery.getOwner());
        delivery.deliveredDelivery(deliveryID);
        assert(delivery.getDelivery(deliveryID).status == DeliveryService.StatusDelivery.DeliveryCompleted);

        vm.prank(CUSTOMER);
        delivery.completeDelivery(deliveryID);
        assert(delivery.getDelivery(deliveryID).status == DeliveryService.StatusDelivery.Completed);
    }
}
