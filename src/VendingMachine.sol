// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IVendingMachine.sol";

contract VendingMachine is IVendingMachine {
    function addInventory(string memory location, uint128 price, uint64 stock) external {}
    function removeInventory(string memory location) external {}
    function restock(string memory location, uint64 stock) external {}
    function reprice(string memory location, uint128 price) external {}
    function purchase(string memory location) external payable {}
    function pause() external {}
    function unpause() external {}
    function collect() external {}
}
