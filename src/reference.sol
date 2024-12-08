// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeliveryOrders {
    struct Order {
        address user;
        string fromLocation;
        string toLocation;
        uint256 distance; // in kilometers
        uint256 price;    // in wei
        uint256 unlockTime; // TimeLock: timestamp when the order can be completed
        bool isCompleted;
    }

    uint256 public orderCount;
    mapping(uint256 => Order) public orders;

    event OrderPlaced(
        uint256 orderId,
        address indexed user,
        string fromLocation,
        string toLocation,
        uint256 distance,
        uint256 price,
        uint256 unlockTime
    );

    event OrderCompleted(uint256 orderId, address indexed user);

    /// @notice Place an order with a TimeLock
    /// @param fromLocation The starting address of the delivery
    /// @param toLocation The destination address
    /// @param distance The distance in kilometers
    /// @param price The delivery price in wei
    /// @param timeLockDuration Time in seconds before the order can be completed
    function placeOrder(
        string memory fromLocation,
        string memory toLocation,
        uint256 distance,
        uint256 price,
        uint256 timeLockDuration
    ) public {
        require(timeLockDuration > 0, "TimeLock duration must be greater than zero");

        uint256 unlockTime = block.timestamp + timeLockDuration; // Current time + lock duration

        orders[orderCount] = Order({
            user: msg.sender,
            fromLocation: fromLocation,
            toLocation: toLocation,
            distance: distance,
            price: price,
            unlockTime: unlockTime,
            isCompleted: false
        });

        emit OrderPlaced(orderCount, msg.sender, fromLocation, toLocation, distance, price, unlockTime);
        orderCount++;
    }

    /// @notice Complete an order after the TimeLock expires
    /// @param orderId The ID of the order to complete
    function completeOrder(uint256 orderId) public {
        require(orderId < orderCount, "Order does not exist");
        Order storage order = orders[orderId];
        require(order.user == msg.sender, "Not your order");
        require(!order.isCompleted, "Order already completed");
        require(block.timestamp >= order.unlockTime, "Cannot complete order before unlock time");

        order.isCompleted = true;

        emit OrderCompleted(orderId, msg.sender);
    }

    /// @notice Get the remaining lock time for an order
    /// @param orderId The ID of the order
    /// @return Remaining time in seconds until the order can be completed
    function getRemainingLockTime(uint256 orderId) public view returns (uint256) {
        require(orderId < orderCount, "Order does not exist");
        Order storage order = orders[orderId];

        if (block.timestamp >= order.unlockTime) {
            return 0; // TimeLock has expired
        } else {
            return order.unlockTime - block.timestamp; // Remaining time in seconds
        }
    }
}