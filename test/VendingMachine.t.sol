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
        machine = new VendingMachine(vm.envAddress("ORACLE"));
        vm.deal(prankUser, 10 ether);
    }

    /// Helper to create item
    function createItem() private returns (bytes3 location, uint128 price, uint64 stock) {
        location = bytes3("D8");
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
        machine.addInventory(bytes3("D9"), 2 * 1e8, 5);

        // removeInventory
        vm.expectRevert();
        machine.removeInventory(bytes3("D8"));

        // restock
        vm.expectRevert();
        machine.restock(bytes3("D8"), 6);

        // reprice
        vm.expectRevert();
        machine.reprice(bytes3("D8"), 3 * 1e8);

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
        emit IVendingMachine.ItemAdded(bytes3("D8"), 2 * 1e8, 5);
        (bytes3 location, uint128 price, uint64 stock) = createItem();

        (uint128 priceNew, uint64 stockNew, uint64 soldNew) = machine.inventory(location);
        assertEq(priceNew, price);
        assertEq(stockNew, stock);
        assertEq(soldNew, 0);

        // No duplicates
        vm.expectRevert();
        createItem();

        // No free items
        vm.expectRevert();
        machine.addInventory(bytes3("D10"), 0, 5);
    }

    function test_removeInventory() public {
        (bytes3 location,,) = createItem();
        vm.expectEmit(true, false, false, false);
        emit IVendingMachine.ItemRemoved(location);
        machine.removeInventory(location);
    }

    function test_restock() public {
        (bytes3 location, uint128 price, uint64 stock) = createItem();
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
        machine.restock(bytes3("D10"), 8);
    }

    function test_reprice() public {
        createItem();
        (, uint64 origStock, uint64 origSold) = machine.inventory(bytes3("D8"));
        vm.expectEmit(true, false, false, true);
        emit IVendingMachine.ItemRepriced(bytes3("D8"), 5 * 1e8);

        machine.reprice(bytes3("D8"), 5 * 1e8);
        (uint128 priceNew, uint64 stockNew, uint64 soldNew) = machine.inventory(bytes3("D8"));
        assertEq(priceNew, 5 * 1e8);
        assertEq(stockNew, origStock);
        assertEq(soldNew, origSold);

        // Only update existing items
        vm.expectRevert();
        machine.reprice(bytes3("D10"), 2 * 1e8);

        // No free items
        vm.expectRevert();
        machine.reprice(bytes3("D8"), 0);
    }

    function test_purchase() public {
        (bytes3 location, uint128 price, uint64 stock) = createItem();
        machine.addInventory(bytes3("D10"), price, 0);
        machine.unpause();
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
        machine.purchase{value: expectedWei}(bytes3("D10"));

        // No nonexistent items
        vm.expectRevert();
        machine.purchase{value: 1 ether}(bytes3("D11"));

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

        assertEq(machine.paused(), true);

        machine.unpause();
        assertEq(machine.paused(), false);
    }

    function test_collect() public {
        uint256 balanceBefore = address(this).balance;
        vm.deal(address(machine), 1 ether);

        machine.collect();
        assertEq(address(this).balance, balanceBefore + 1 ether);
        assertEq(address(machine).balance, 0);
    }

    receive() external payable {}
}
