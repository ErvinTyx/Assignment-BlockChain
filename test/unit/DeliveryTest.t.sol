// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {DeployDelivery} from "../../script/DeployDelivery.s.sol";
import {DeliveryService} from "../../src/Delivery.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DeliveryTest is Test {
    DeliveryService public delivery;
    HelperConfig public helperConfig;

    enum StatusDelivery {
        Scheduled,
        Cancelled,
        Delivery,
        DeliveryCompleted,
        Completed
    }

    event DeliveryScheduled(
        uint256 deliveryID,
        address indexed customer,
        string fromAddress,
        string toAddress,
        uint256 price,
        uint256 scheduledTime
    );
    event DeliveryModified(uint256 deliveryID, uint256 newScheduledTime, uint256 remainingAttempts);
    event DeliveryCancelled(uint256 deliveryID, address indexed customer);

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

    modifier ScheduledDelivery() {
        vm.prank(CUSTOMER);
        newTimestamp = 3 hours;
        deliveryID = delivery.scheduleDelivery{value: SEND_VALUE}(FROM_ADDRESS, TO_ADDRESS, PRICE, newTimestamp);
        _;
    }

    modifier ForCancelDelivery() {
        vm.prank(CUSTOMER);
        newTimestamp = 9 hours;
        deliveryID = delivery.scheduleDelivery{value: 1 ether}(FROM_ADDRESS, TO_ADDRESS, PRICE, newTimestamp);
        _;
    }

    function setUp() external {
        DeployDelivery deployDelivery = new DeployDelivery();
        delivery = deployDelivery.run();
        vm.deal(CUSTOMER, STARTING_BALANCE);
    }

    function testMinDelay() public view {
        assert(delivery.getMinimumDelay() == 1 hours);
    }

    function testModificationLimit() public view {
        assert(delivery.getModificationLimit() == 3);
    }

    function testCancellationLimit() public view {
        assert(delivery.getCancellationLimit() == 3);
    }

    function testCoolingPeriod() public view {
        assertEq(delivery.getCoolingPeriod(), 30 days);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = delivery.getVersion();
        console.log("Price feed version:", version);
        if (block.chainid == 31337) {
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            assertEq(version, 6);
        } else {
            assertEq(version, 4);
        }
    }

    function testScheduledDeliveryDontPayEnough() public {
        vm.prank(CUSTOMER);
        vm.expectRevert();
        delivery.scheduleDelivery(FROM_ADDRESS, TO_ADDRESS, PRICE, (block.timestamp + MIN_DELAY + 36));
    }

    function testScheduledDeliveryLessThanMinDelay() public {
        vm.prank(CUSTOMER);
        vm.expectRevert();
        delivery.scheduleDelivery(FROM_ADDRESS, TO_ADDRESS, PRICE, (block.timestamp));
    }

    function testScheduledDelivery() public {
        vm.prank(CUSTOMER);
        newTimestamp = block.timestamp + MIN_DELAY + 36;
        deliveryID = delivery.scheduleDelivery{value: SEND_VALUE}(FROM_ADDRESS, TO_ADDRESS, PRICE, newTimestamp);
        assert(delivery.getDelivery(deliveryID).status == DeliveryService.StatusDelivery.Scheduled);
    }

    function testScheduledDeliveryEmits() public {
        vm.prank(CUSTOMER);
        newTimestamp = MIN_DELAY + 37;
        uint256 INITIAL_ID = 0;
        vm.expectEmit(true, false, false, true, address(delivery));
        emit DeliveryScheduled(INITIAL_ID, CUSTOMER, FROM_ADDRESS, TO_ADDRESS, PRICE, newTimestamp + block.timestamp);
        deliveryID = delivery.scheduleDelivery{value: SEND_VALUE}(FROM_ADDRESS, TO_ADDRESS, PRICE, newTimestamp);
    }

    function testModifyDeliveryModificationLimitExceeded() public ScheduledDelivery {
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(CUSTOMER);
            delivery.modifyDelivery(deliveryID, newTimestamp);
        }

        vm.prank(CUSTOMER);
        vm.expectRevert();
        delivery.modifyDelivery(deliveryID, newTimestamp);
    }

    function testModifyDeliveryNotWithin2HoursOfScheduledTime() public ScheduledDelivery {
        vm.warp(block.timestamp + 2 hours);
        vm.roll(block.number + 1);

        vm.prank(CUSTOMER);
        vm.expectRevert();
        delivery.modifyDelivery(deliveryID, newTimestamp);
    }

    function testModifyDeliveryNotOwnerModify() public ScheduledDelivery {
        vm.expectRevert();
        delivery.modifyDelivery(deliveryID, newTimestamp);
    }

    function testModifyDeliveryEmits() public ScheduledDelivery {
        vm.prank(CUSTOMER);
        vm.expectEmit(true, false, false, true, address(delivery));
        emit DeliveryModified(deliveryID, newTimestamp, MODIFICATION_LIMIT - 1);
        delivery.modifyDelivery(deliveryID, newTimestamp);
    }

    function testCancelDeliveryCannotCancelAfterScheduledTime() public ScheduledDelivery {
        // @dev change time to 5 minutes after scheduled time and adds a new block
        vm.warp(newTimestamp + 5 minutes);
        vm.roll(block.number + 1);

        vm.prank(CUSTOMER);
        vm.expectRevert();
        delivery.cancelDelivery(deliveryID);
    }

    function testCancelDeliveryStatusCancel() public ScheduledDelivery {
        vm.prank(CUSTOMER);
        delivery.cancelDelivery(deliveryID);
        assert(delivery.getDelivery(deliveryID).status == DeliveryService.StatusDelivery.Cancelled);
    }

    function testCancelDeliveryStatusCancelEmits() public ScheduledDelivery {
        vm.prank(CUSTOMER);
        vm.expectEmit(true, false, false, true, address(delivery));
        emit DeliveryCancelled(deliveryID, CUSTOMER);
        delivery.cancelDelivery(deliveryID);
    }

    function testCancelDeliveryRefund100Percent() public ForCancelDelivery {
        vm.prank(CUSTOMER);
        delivery.cancelDelivery(deliveryID);
        // pay 5 ether but price is 25e7 and total money is 10 ether
        // price for 1 ether is 2000usd
        // so if price is 5usd also in 5e8 is 25e7 ether
        assertEq(10 ether, CUSTOMER.balance);
    }

    function testCancelDeliveryRefund75Percent() public ForCancelDelivery {
        vm.warp(7 hours + block.timestamp + 1 minutes);
        vm.roll(block.number + 1);

        vm.prank(CUSTOMER);
        delivery.cancelDelivery(deliveryID);
        // pay 5 ether but price is 25e7 and total money is 10 ether
        // price for 1 ether is 2000usd
        // so if price is 5usd also in 5e8 is 25e7 ether
        assertEq(5 ether + (25e7 * 75 / 100), CUSTOMER.balance);
    }

    function testCancelDeliveryRefund50Percent() public ForCancelDelivery {
        vm.warp(8 hours + block.timestamp + 1 minutes);
        vm.roll(block.number + 1);

        vm.prank(CUSTOMER);
        delivery.cancelDelivery(deliveryID);
        // pay 5 ether but price is 25e7 and total money is 10 ether
        // price for 1 ether is 2000usd
        // so if price is 5usd also in 5e8 is 25e7 ether
        assertEq(5 ether + (25e7 * 50 / 100), CUSTOMER.balance);
    }
}
