// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {DeployDelivery} from "../../script/DeployDelivery.s.sol";
import {DeliveryService} from "../../src/Delivery.sol";
import {Test,console} from "forge-std/Test.sol";
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

    string public constant FROM_ADDRESS = "PJ";
    string public constant TO_ADDRESS = "Seremban";
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

    function testMinDelay() public view {
        assert(delivery.getMinimumDelay() == 1 hours);
    }

    function testModificationLimit() public view{
        assert(delivery.getModificationLimit() ==3);
    }
    
    function testCancellationLimit() public view{
        assert(delivery.getCancellationLimit() ==3);
    }

    function testCoolingPeriod() public view{
        assertEq(delivery.getCoolingPeriod(),30 days);
    }

    

    function testPriceFeedVersionIsAccurate() public view{
        uint256 version = delivery.getVersion();   
        console.log("Price feed version:", version);
        if(block.chainid == 31337){
            assertEq(version,4);
        }
        else if(block.chainid == 1){
            assertEq(version,6);
        }
        else{
            assertEq(version,4);
        }
    }

    function testScheduledDeliveryDontPayEnough() public{
        vm.prank(CUSTOMER);
        vm.expectRevert();
        delivery.scheduleDelivery(FROM_ADDRESS, TO_ADDRESS, PRICE, (block.timestamp + MIN_DELAY+ 36));
    }

    function testScheduledDeliveryLessThanMinDelay() public{
        vm.prank(CUSTOMER);
        vm.expectRevert();
        delivery.scheduleDelivery(FROM_ADDRESS, TO_ADDRESS, PRICE, (block.timestamp));
    }

    function testScheduledDelivery() public{
        vm.prank(CUSTOMER);
        uint256 deliveryID;
        uint256 newTimestamp = block.timestamp + MIN_DELAY + 36;
        deliveryID = delivery.scheduleDelivery{value: SEND_VALUE}(FROM_ADDRESS, TO_ADDRESS, PRICE, newTimestamp);
        assert(delivery.getDelivery(deliveryID).status == DeliveryService.StatusDelivery.Scheduled );
    }


}
