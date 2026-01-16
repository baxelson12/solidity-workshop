// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "smartcontractkit-chainlink-evm-1.5.0/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "solady-0.1.26/src/auth/Ownable.sol";
import "./IVendingMachine.sol";

contract VendingMachine is IVendingMachine, Ownable {
    mapping(string => Item) public inventory;
    bool public paused = false;
    AggregatorV3Interface public feed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /// @notice Ensures functions this is attached to cannot be called while paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor() {
        _initializeOwner(msg.sender);
    }

    function addInventory(string memory location, uint128 price, uint64 stock) external onlyOwner {
        Item storage item = inventory[location];
        require(item.price == 0, "Cannot overwrite item");
        require(price > 0, "Cannot create free item");

        item.price = price;
        item.stock = stock;
        emit ItemAdded(location, price, stock);
    }

    function removeInventory(string memory location) external onlyOwner {
        delete inventory[location];
        emit ItemRemoved(location);
    }

    function restock(string memory location, uint64 stock) external onlyOwner {
        Item storage item = inventory[location];
        require(item.price > 0, "Item does not exist");

        item.stock += stock;
        emit ItemRestocked(location, item.stock);
    }

    function reprice(string memory location, uint128 price) external onlyOwner {
        Item storage item = inventory[location];
        require(item.price > 0, "Item does not exist");
        require(price > 0, "Cannot create free item");

        item.price = price;
        emit ItemRepriced(location, price);
    }

    function purchase(string memory location) external payable whenNotPaused {
        Item storage item = inventory[location];
        require(item.price > 0, "Item does not exist");
        require(item.stock > 0, "Item is out of stock");

        (, int256 ethValueWei,,,) = feed.latestRoundData();
        uint256 expectedWei = (uint256(item.price) * 1e18) / uint256(ethValueWei);
        require(msg.value >= expectedWei, "Value received is less than item price");

        item.sold++;
        item.stock--;

        emit ItemPurchased(location, item.stock, item.sold);
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
        require(amount > 0, "Nothing to transfer");
        (bool success,) = owner().call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsCollected(amount);
    }
}
