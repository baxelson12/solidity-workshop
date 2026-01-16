// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "smartcontractkit-chainlink-evm-1.5.0/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "solady-0.1.26/src/auth/Ownable.sol";
import "./IVendingMachine.sol";
import "./Pausable.sol";

contract VendingMachine is IVendingMachine, Ownable, Pausable {
    /// Maintains a mapping of all items in the vending machine
    mapping(bytes3 => Item) public inventory;
    /// Reference to the chainlink Oracle for ETH/USD price
    AggregatorV3Interface public immutable feed;

    constructor(address oracle) {
        _initializeOwner(msg.sender);
        feed = AggregatorV3Interface(oracle);
    }

    function addInventory(bytes3 location, uint128 price, uint64 stock) external onlyOwner {
        Item storage item = inventory[location];
        if (item.price > 0) revert NoOverwrites();
        if (price == 0) revert NoFreeItems();

        item.price = price;
        item.stock = stock;
        emit ItemAdded(location, price, stock);
    }

    function removeInventory(bytes3 location) external onlyOwner {
        delete inventory[location];
        emit ItemRemoved(location);
    }

    function restock(bytes3 location, uint64 stock) external onlyOwner {
        Item storage item = inventory[location];
        if (item.price == 0) revert NonexistentItem();

        item.stock += stock;
        emit ItemRestocked(location, item.stock);
    }

    function reprice(bytes3 location, uint128 price) external onlyOwner {
        Item storage item = inventory[location];
        if (item.price == 0) revert NonexistentItem();
        if (price == 0) revert NoFreeItems();

        item.price = price;
        emit ItemRepriced(location, price);
    }

    function purchase(bytes3 location) external payable whenNotPaused {
        Item storage item = inventory[location];
        if (item.price == 0) revert NonexistentItem();
        if (item.stock == 0) revert OutOfStock();

        (, int256 ethValueWei,,,) = feed.latestRoundData();
        uint256 expectedWei = (uint256(item.price) * 1e18) / uint256(ethValueWei);
        if (msg.value < expectedWei) revert IncorrectValueSent();

        emit ItemPurchased(location, --item.stock, ++item.sold);
    }

    function pause() external onlyOwner {
        paused = true;
        emit PauseStateChanged(paused);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit PauseStateChanged(paused);
    }

    function collect() external onlyOwner {
        uint256 amount = address(this).balance;
        if (amount == 0) revert NoZeroTransfers();
        (bool success,) = owner().call{value: amount}("");
        if (!success) revert CollectFailed();

        emit FundsCollected(amount);
    }
}
