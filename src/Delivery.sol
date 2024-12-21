// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Test, console} from "forge-std/Test.sol";
import {PriceConverter} from "./PriceConverter.sol";

/**
 * @title DeliveryService
 * @author Teoh Yu Xiang, Teo Ka Teakm, Toh Xin Ping and Tan Chin Sea
 * @notice
 */
contract DeliveryService {
    error DeliveryService__AlreadyCancelled();
    error DeliveryService__RefundFailed();
    error DeliveryService__deliveryDeliveryWrongState();
    error DeliveryService__AlreadyCancelledOrCompleted();
    error DeliveryService__HaventFinishedScheduleTime();
    error DeliveryService__CancelDeliveryWrongState();
    error DeliveryService__NotInModifyState();
    error DeliveryService__completeDeliveryWrongState();

    /* interfaces, libraries, contracts */
    // Contract variables
    AggregatorV3Interface private s_priceFeed;

    /* Type Declarations*/
    using PriceConverter for uint256;

    enum StatusDelivery {
        Scheduled,
        Cancelled,
        Delivery,
        DeliveryCompleted,
        Completed
    }

    // Structs
    struct Delivery {
        address customer;
        string fromAddress;
        string toAddress;
        uint256 price;
        uint256 payAmount;
        uint256 scheduledTime; // Scheduled execution time (timestamp)
        uint256 completedTime;
        uint256 modificationAttempts;
        StatusDelivery status;
        uint256 createdTime;
    }

    /* State variables*/
    // Mappings
    mapping(uint256 => Delivery) public deliveries; // deliveryID -> Delivery
    mapping(address => uint256) public userCancellations; // Tracks cancellations per user
    mapping(address => uint256) public lastCancellationTime; // Last cancellation timestamp
    uint256 public totalDeliveries;

    // Constants
    uint256 private constant MIN_DELAY = 1 hours; // Minimum scheduling delay
    uint256 private constant MODIFICATION_LIMIT = 3;
    uint256 private constant COOLING_PERIOD = 30 days;
    uint256 private constant CANCELLATION_LIMIT = 3;

    // immutable variables
    address private immutable i_ownerContract;

    // Events
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

    // Modifiers
    modifier onlyCustomer(uint256 deliveryID) {
        require(msg.sender == deliveries[deliveryID].customer, "Not your delivery.");
        _;
    }

    modifier canModify(uint256 deliveryID) {
        Delivery storage delivery = deliveries[deliveryID];
        require(block.timestamp < delivery.scheduledTime - 2 hours, "Cannot modify within 2 hours of scheduled time.");
        require(delivery.modificationAttempts < MODIFICATION_LIMIT, "Modification limit exceeded.");
        _;
    }

    modifier canCancel(uint256 deliveryID) {
        require(block.timestamp < deliveries[deliveryID].scheduledTime, "Cannot cancel after scheduled time.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == i_ownerContract, "Only the owner can call this function.");
        _;
    }

    /*Functions */
    // constructor
    constructor(address _priceFeed) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        i_ownerContract = msg.sender;
    }
    // Core Functions

    /// @notice Modify an existing delivery
    function modifyDelivery(uint256 deliveryID, uint256 newScheduledTime)
        external
        onlyCustomer(deliveryID)
        canModify(deliveryID)
    {
        require(newScheduledTime > block.timestamp + MIN_DELAY, "New scheduled time must meet minimum delay.");

        Delivery storage delivery = deliveries[deliveryID];

        if (delivery.status != StatusDelivery.Scheduled) {
            revert DeliveryService__NotInModifyState();
        }
        delivery.scheduledTime = newScheduledTime;
        delivery.modificationAttempts++;

        emit DeliveryModified(deliveryID, newScheduledTime, MODIFICATION_LIMIT - delivery.modificationAttempts);
    }

    /// @notice Cancel a delivery before the scheduled time
    function cancelDelivery(uint256 deliveryID) external onlyCustomer(deliveryID) canCancel(deliveryID) {
        Delivery storage delivery = deliveries[deliveryID];

        // Check state is in scheduled state
        if (delivery.status != StatusDelivery.Scheduled) revert DeliveryService__CancelDeliveryWrongState();

        // Cache `scheduledTime` and `price` for gas efficiency
        uint256 scheduledTime = delivery.scheduledTime;
        uint256 price = delivery.payAmount;

        // Mark as cancelled
        delivery.status = StatusDelivery.Cancelled;

        // Update user cancellation state
        unchecked {
            userCancellations[msg.sender]++;
            lastCancellationTime[msg.sender] = block.timestamp;
        }
        // Refund calculation
        uint256 refund;
        uint256 timeRemaining = scheduledTime - block.timestamp;

        if (timeRemaining > 2 hours) {
            refund = price; // Full refund
        } else if (timeRemaining > 1 hours) {
            refund = (price * 75) / 100; // 75% refund
        } else {
            refund = (price * 50) / 100; // 50% refund
        }
        // Transfer the refund
        bool success = payable(msg.sender).send(refund);
        if (!success) revert DeliveryService__RefundFailed();

        emit DeliveryCancelled(deliveryID, msg.sender);
    }

    /// @notice Complete the delivery (can only be done after the scheduled time)
    function completeDelivery(uint256 deliveryID) external onlyCustomer(deliveryID) {
        Delivery storage delivery = deliveries[deliveryID];
        if (delivery.status != StatusDelivery.DeliveryCompleted) {
            revert DeliveryService__completeDeliveryWrongState();
        }

        delivery.status = StatusDelivery.Completed;

        emit DeliveryCompleted(deliveryID, msg.sender);
    }

    function outFordelivery(uint256 deliveryID) external onlyOwner {
        Delivery storage delivery = deliveries[deliveryID];
        if (delivery.status != StatusDelivery.Scheduled) {
            revert DeliveryService__AlreadyCancelledOrCompleted();
        }
        if (delivery.scheduledTime > block.timestamp) {
            revert DeliveryService__HaventFinishedScheduleTime();
        }

        delivery.status = StatusDelivery.Delivery;
        emit OutForDelivery(deliveryID);
    }

    /// @notice Delivered to the customer
    function deliveredDelivery(uint256 deliveryID) external onlyOwner {
        Delivery storage delivery = deliveries[deliveryID];
        require(block.timestamp >= delivery.scheduledTime, "Cannot complete before scheduled time.");
        if (delivery.status != StatusDelivery.Delivery) {
            revert DeliveryService__deliveryDeliveryWrongState();
        }
        delivery.status = StatusDelivery.DeliveryCompleted;
        emit DeliveryDelivered(deliveryID);
    }

    /// @notice Withdraw funds
    function withdrawFunds() external onlyOwner {
        payable(i_ownerContract).transfer(address(this).balance);
    }

    /// @notice Get cooling-off period status
    function isCoolingOff(address user) external view returns (bool) {
        return userCancellations[user] >= CANCELLATION_LIMIT
            && block.timestamp < lastCancellationTime[user] + COOLING_PERIOD;
    }

    /// @notice Schedule a new delivery
    function scheduleDelivery(string memory fromAddress, string memory toAddress, uint256 price, uint256 scheduledTime)
        public
        payable
        returns (uint256)
    {
        scheduledTime = scheduledTime + block.timestamp;
        // Check minimum delay
        require(scheduledTime > block.timestamp + MIN_DELAY, "Scheduled time must meet minimum delay.");

        // Check user cooling-off period
        if (userCancellations[msg.sender] >= CANCELLATION_LIMIT) {
            require(block.timestamp > lastCancellationTime[msg.sender] + COOLING_PERIOD, "Cooling-off period active.");
        }

        // Check price
        require(msg.value.getConversionRate(s_priceFeed) >= price, "Not enough money to cover delivery cost.");

        uint256 deliveryID = totalDeliveries++;
        deliveries[deliveryID] = Delivery({
            customer: msg.sender,
            fromAddress: fromAddress,
            toAddress: toAddress,
            price: price,
            payAmount: msg.value,
            scheduledTime: scheduledTime,
            completedTime: 0,
            modificationAttempts: 0,
            status: StatusDelivery.Scheduled,
            createdTime: block.timestamp
        });

        emit DeliveryScheduled(deliveryID, msg.sender, fromAddress, toAddress, price, msg.value, scheduledTime);
        return deliveryID;
    }

    /// @notice View delivery details
    function getDelivery(uint256 deliveryID) external view returns (Delivery memory) {
        return deliveries[deliveryID];
    }

    // Getter
    function getMinimumDelay() external pure returns (uint256) {
        return MIN_DELAY;
    }

    function getModificationLimit() external pure returns (uint256) {
        return MODIFICATION_LIMIT;
    }

    function getCancellationLimit() external pure returns (uint256) {
        return CANCELLATION_LIMIT;
    }

    function getCoolingPeriod() external pure returns (uint256) {
        return COOLING_PERIOD;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getOwner() public view returns (address) {
        return i_ownerContract;
    }
}
