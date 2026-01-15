// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVendingMachine {
    /// Struct representing an item/slot of a vending machine
    struct Item {
        /// Price of item in USD with 8 decimals (10^8)
        uint128 price;
        /// How many of this item are available
        uint64 stock;
        /// How many of this item have been sold
        uint64 sold;
    }

    /// Emitted when a new item is added
    event ItemAdded(string indexed location, uint128 price, uint64 stock);
    /// Emitted when an item is removed
    event ItemRemoved(string indexed location);
    /// Emitted when an item is restocked
    event ItemRestocked(string indexed location, uint64 stock);
    /// Emitted when an item is repriced
    event ItemRepriced(string indexed location, uint128 price);
    /// Emitted when an item is purchased
    event ItemPurchased(string indexed location, uint64 stock, uint64 sold);
    /// Emitted when the contract is paused/unpaused
    event PauseStateChanged(bool paused);
    /// Emitted when funds from the contract are collected
    event FundsCollected(uint256 amount);

    /// @notice Create a new Item in the vending machine
    /// @param location The location of the item within the vending machine
    /// @param price The price of the item in USD with 8 decimals (10^8)
    /// @param stock How many of the added item are currently available
    /// @dev Location is defined by {Alpha}{Numeric} e.g D3
    /// @dev Location must be within bounds defined on initialization
    function addInventory(string memory location, uint128 price, uint64 stock) external;

    /// @notice Remove the specified Item in the vending machine
    /// @param location The location of the item within the vending machine
    /// @dev Location is defined by {Alpha}{Numeric} e.g D3
    function removeInventory(string memory location) external;

    /// @notice Update the stock of the specified Item
    /// @param location The location of the item within the vending machine
    /// @param stock The amount of inventory to add
    /// @dev Inventory is additive, cannot subtract inventory
    /// @dev Location is defined by {Alpha}{Numeric} e.g D3
    function restock(string memory location, uint64 stock) external;

    /// @notice Update the price of the specified item
    /// @param location The location of the item within the vending machine
    /// @param price The new price of the item in USD with 8 decimals (10^18)
    /// @dev Location is defined by {Alpha}{Numeric} e.g D3
    function reprice(string memory location, uint128 price) external;

    /// @notice Purchase the specified Item
    /// @param location The location of the item within the vending machine
    /// @dev Location is defined by {Alpha}{Numeric} e.g D3
    function purchase(string memory location) external payable;

    /// @notice Pause the contract
    /// @dev Halts purchases until unpaused
    function pause() external;

    /// @notice Unpause the contract
    /// @dev Allows purchases until paused
    function unpause() external;

    /// @notice Collect funds from contract
    /// @dev Funds will be transferred to contract owner
    function collect() external;
}
