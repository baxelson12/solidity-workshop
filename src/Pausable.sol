// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract Pausable {
    /// Is contract paused?
    bool public paused = true;

    /// Contract is paused
    error ContractPaused();

    /// @notice Ensures functions this is attached to cannot be called while paused
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }
}
