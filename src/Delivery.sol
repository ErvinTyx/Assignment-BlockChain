// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

/**
 * @title DeliveryService
 * @author Teoh Yu Xiang, Teo Ka Teakm, Toh Xin Ping and Tan Chin Sea
 * @notice
 */
contract DeliveryService {
    // Type Declarations
    using PriceConverter for uint256;

    // constuructor
    constructor(address _priceFeed) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        i_ownerContract = msg.sender;
    }

    // Structs
    struct Delivery {
        address customer;
        string fromAddress;
        string toAddress;
        uint256 price;
        uint256 scheduledTime; // Scheduled execution time (timestamp)
        uint256 completedTime;
        uint256 modificationAttempts;
        bool isDelivered;
        bool isCompleted;
        bool isCancelled;
        uint256 createdTime;
    }

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

    // variables
    AggregatorV3Interface private s_priceFeed;

    // Events
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
    event DeliveryCompleted(uint256 deliveryID, address indexed customer);
    event DeliveryDelivered(uint256 deliveryID);

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

    // Core Functions

    /// @notice Schedule a new delivery
    function scheduleDelivery(string memory fromAddress, string memory toAddress, uint256 price, uint256 scheduledTime)
        public
        payable
        returns (uint256)
    {
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
            scheduledTime: scheduledTime,
            completedTime: 0,
            modificationAttempts: 0,
            isCompleted: false,
            isDelivered: false,
            isCancelled: false,
            createdTime: block.timestamp
        });

        emit DeliveryScheduled(deliveryID, msg.sender, fromAddress, toAddress, price, scheduledTime);
        return deliveryID;
    }

    /// @notice Modify an existing delivery
    function modifyDelivery(uint256 deliveryID, uint256 newScheduledTime)
        external
        onlyCustomer(deliveryID)
        canModify(deliveryID)
    {
        require(newScheduledTime > block.timestamp + MIN_DELAY, "New scheduled time must meet minimum delay.");

        Delivery storage delivery = deliveries[deliveryID];
        delivery.scheduledTime = newScheduledTime;
        delivery.modificationAttempts++;

        emit DeliveryModified(deliveryID, newScheduledTime, MODIFICATION_LIMIT - delivery.modificationAttempts);
    }

    /// @notice Cancel a delivery before the scheduled time
    function cancelDelivery(uint256 deliveryID) external onlyCustomer(deliveryID) canCancel(deliveryID) {
        Delivery storage delivery = deliveries[deliveryID];
        require(!delivery.isCancelled, "Delivery already cancelled.");

        delivery.isCancelled = true;
        userCancellations[msg.sender]++;
        lastCancellationTime[msg.sender] = block.timestamp;

        emit DeliveryCancelled(deliveryID, msg.sender);

        // Refund the customer
        if (block.timestamp + 7200 > delivery.scheduledTime) {
            payable(msg.sender).transfer(delivery.price);
        } else if (block.timestamp + 3600 > delivery.scheduledTime) {
            payable(msg.sender).transfer(delivery.price * 3 / 4);
        } else {
            payable(msg.sender).transfer(delivery.price / 2);
        }
    }

    /// @notice Complete the delivery (can only be done after the scheduled time)
    function completeDelivery(uint256 deliveryID) external onlyCustomer(deliveryID) {
        Delivery storage delivery = deliveries[deliveryID];
        require(!delivery.isCancelled, "Delivery is cancelled.");
        require(delivery.isDelivered, "Delivery not delivered yet.");

        delivery.isCompleted = true;

        emit DeliveryCompleted(deliveryID, msg.sender);
    }

    /// @notice Delivered to the customer
    function deliveredDelivery(uint256 deliveryID) external onlyOwner {
        Delivery storage delivery = deliveries[deliveryID];
        require(block.timestamp >= delivery.scheduledTime, "Cannot complete before scheduled time.");
        require(!delivery.isDelivered, "Delivery already delivered.");
        delivery.isDelivered = true;
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

    // Fallback to accept payments
    receive() external payable {}
}
