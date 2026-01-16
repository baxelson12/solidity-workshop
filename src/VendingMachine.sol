// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IVendingMachine.sol";

contract VendingMachine is IVendingMachine {
    mapping(string => Item) public inventory;
    bool public paused = true;

    constructor() {}

    function addInventory(string memory location, uint128 price, uint64 stock) external {
        Item storage item = inventory[location];
        require(item.price == 0, "Cannot overwrite item");
        require(price > 0, "Cannot create free item");

        item.price = price;
        item.stock = stock;
        emit ItemAdded(location, price, stock);
    }

    function removeInventory(string memory location) external {
        delete inventory[location];
        emit ItemRemoved(location);
    }
    function restock(string memory location, uint64 stock) external {}
    function reprice(string memory location, uint128 price) external {}
    function purchase(string memory location) external payable {}

    function pause() external {
        paused = true;
        emit PauseStateChanged(paused);
    }

    function unpause() external {
        paused = false;
        emit PauseStateChanged(paused);
    }
    function collect() external {}
}
