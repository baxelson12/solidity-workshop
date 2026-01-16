// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "smartcontractkit-chainlink-evm-1.5.0/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IVendingMachine} from "../src/IVendingMachine.sol";
import {VendingMachine} from "../src/VendingMachine.sol";

contract VendingMachineTest is Test {
    VendingMachine public machine;
    address public prankUser = makeAddr("prankUser");
    AggregatorV3Interface feed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function setUp() public {
        machine = new VendingMachine();
        vm.deal(prankUser, 10 ether);
    }

    /// Helper to create item
    function createItem() private returns (string memory location, uint128 price, uint64 stock) {
        location = "D8";
        price = 2 * 1e8;
        stock = 5;
        machine.addInventory(location, price, stock);
    }

    /**
     * Ownership checks
     */
    function testRevert_OwnershipChecks() public {
        createItem();
        vm.startPrank(prankUser);

        // addInventory
        vm.expectRevert();
        machine.addInventory("D9", 2 * 1e8, 5);

        // removeInventory
        vm.expectRevert();
        machine.removeInventory("D8");

        // restock
        vm.expectRevert();
        machine.restock("D8", 6);

        // reprice
        vm.expectRevert();
        machine.reprice("D8", 3 * 1e8);

        // pause
        vm.expectRevert();
        machine.pause();

        // unpause
        vm.expectRevert();
        machine.unpause();

        // collect
        vm.expectRevert();
        machine.collect();
    }

    function test_addInventory() public {
        vm.expectEmit(true, false, false, true);
        emit IVendingMachine.ItemAdded("D8", 2 * 1e8, 5);
        (string memory location, uint128 price, uint64 stock) = createItem();

        (uint128 priceNew, uint64 stockNew, uint64 soldNew) = machine.inventory(location);
        assertEq(priceNew, price);
        assertEq(stockNew, stock);
        assertEq(soldNew, 0);

        // No duplicates
        vm.expectRevert();
        createItem();

        // No free items
        vm.expectRevert();
        machine.addInventory("D10", 0, 5);
    }

    function test_removeInventory() public {
        (string memory location,,) = createItem();
        vm.expectEmit(true, false, false, false);
        emit IVendingMachine.ItemRemoved(location);
        machine.removeInventory(location);

        // Only delete existing items
        vm.expectRevert();
        machine.removeInventory(location);
    }

    function test_restock() public {
        (string memory location, uint128 price, uint64 stock) = createItem();
        vm.expectEmit(true, false, false, true);
        emit IVendingMachine.ItemRestocked(location, stock + 5);
        machine.restock(location, 5);

        (uint128 priceNew, uint64 stockNew, uint64 soldNew) = machine.inventory(location);
        assertEq(stockNew, 10);
        assertEq(priceNew, price);
        assertEq(soldNew, 0);
        vm.assertGt(stockNew, stock);

        // Only update existing items
        vm.expectRevert();
        machine.restock("D10", 8);
    }

    function test_reprice() public {
        createItem();
        (uint128 origPrice, uint64 origStock, uint64 origSold) = machine.inventory("D8");
        vm.expectEmit(true, false, false, true);
        emit IVendingMachine.ItemRepriced("D8", 5 * 1e8);

        machine.reprice("D8", 5 * 1e8);
        (uint128 priceNew, uint64 stockNew, uint64 soldNew) = machine.inventory("D8");
        assertEq(priceNew, 5 * 1e8);
        assertEq(stockNew, origStock);
        assertEq(soldNew, origSold);

        // Only update existing items
        vm.expectRevert();
        machine.reprice("D10", 2 * 1e8);

        // No free items
        vm.expectRevert();
        machine.reprice("D8", 0);
    }

    function test_purchase() public {
        (string memory location, uint128 price, uint64 stock) = createItem();
        machine.addInventory("D10", price, 0);
        (, uint64 savedStock, uint64 savedTotalSold) = machine.inventory(location);
        (, int256 answer,,,) = feed.latestRoundData();
        uint256 expectedWei = (uint256(price) * 1e18) / uint256(answer);

        vm.expectEmit(true, false, false, true);
        emit IVendingMachine.ItemPurchased(location, stock - 1, savedTotalSold + 1);

        vm.startPrank(prankUser);
        machine.purchase{value: expectedWei}(location);

        (, uint64 stockAfterPurchase, uint64 totalSoldAfterPurchase) = machine.inventory(location);
        assertEq(stockAfterPurchase, savedStock - 1);
        assertEq(totalSoldAfterPurchase, savedTotalSold + 1);

        // No out of stock items
        vm.expectRevert();
        machine.purchase{value: expectedWei}("D10");

        // No nonexistent items
        vm.expectRevert();
        machine.purchase{value: 1 ether}("D15");

        // No free items
        vm.expectRevert();
        machine.purchase{value: 0}(location);

        vm.stopPrank();

        // Do not sell while paused
        machine.pause();
        vm.expectRevert();
        machine.purchase{value: expectedWei}(location);
    }

    function test_pauseUnpause() public {
        machine.pause();

        assertEq(machine.paused, true);

        machine.unpause();
        assertEq(machine.paused, false);
    }

    function test_collect() public {
        (string memory location, uint128 price, uint64 stock) = createItem();
        (, int256 answer,,,) = feed.latestRoundData();
        uint256 expectedWei = (uint256(price) * 1e18) / uint256(answer);

        vm.startPrank(prankUser);
        machine.purchase{value: expectedWei}(location);

        // Do not allow unauthorized user to collect
        vm.expectRevert();
        machine.collect();
        vm.stopPrank();

        // Should transfer contract balance
        machine.collect();
        assertEq(address(msg.sender).balance, expectedWei);
        assertEq(address(machine).balance, 0);

        // Do not transfer 0 funds
        vm.expectRevert();
        machine.collect();
    }
}
