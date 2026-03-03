# Relevant Documentation
- Solidity docs: https://docs.soliditylang.org/en/v0.8.34/
- Foundry docs: https://www.getfoundry.sh/introduction/getting-started
- Relevant Chainlink docs (obtaining price from oracle): https://docs.chain.link/data-feeds/price-feeds/addresses?page=1&search=eth%2Fusd

# Repository Structure
This repository contains 5 branches labelled in stages:
- `stage-1/hello-world`
	- The starting `foundry init` project
- `stage-2/interface-implementation`
	- The interface, or "blueprint", for the smart contract to be built
- `stage-3/unit-tests`
	- Smart contract tests to ensure the final smart contract will work as expected
	- ##### **NOTE:** This is the starting point if you choose to develop the smart contract on your own
- `stage-4/implementation`
- `stage-5/refactoring`

# Project Setup
> It is highly recommended you fork this repository and work off of that if you choose to develop the final smart contract yourself.  IF you fork the repository, keep in mind the clone URL will change to something like `git@github.com:{your_username}/solidity-workshop.git`.

- Clone this repository: `git clone --recursive git@github.com:baxelson12/solidity-workshop.git`
- `cd` into the directory.  At this point you will be at the `stage-1/hello-world` branch.  You can switch to other branches via `git checkout {branch name}`

# Test Driven Development
If you would like to build the vending machine contract on your own, you can begin from `stage-3/unit-tests`.  Starting from this point will enable you to run the tests in "watch" mode in the background, which you can reference as you code to ensure your final smart contract is correct.  Recommended steps:
1. Create a new branch to work from, which is based on the `stage-3/unit-tests` branch.
	1. `git checkout -b feature/vending-machine stage-3/unit-tests`
2. Install necessary dependencies.
	1. `forge soldeer install`
3. In a separate terminal window, or within VSCode's terminal window run `forge test --fork-url mainnet --watch`

At this point, you should be met with an error in your terminal similar to:
```bash
[⠊] Compiling...
[⠑] Compiling 3 files with Solc 0.8.33
[⠘] Solc 0.8.33 finished in 572.66ms
Error: Compiler run failed:
Error (9582): Member "inventory" not found or not visible after argument-dependent lookup in contract VendingMachine.
  --> test/VendingMachine.t.sol:68:63:
   |
68 |         (uint128 priceNew, uint64 stockNew, uint64 soldNew) = machine.inventory(location);
   |                                                               ^^^^^^^^^^^^^^^^^

```

This is to be expected, as the code within `VendingMachine.sol` has not been written yet.  You can leave this window open and running, and begin adding in your code at this point.  As you add in your global variables and functions, the test window will update on its own and begin to show passing tests as you complete the relevant functions.  If at any point you feel lost, you can reference the `stage-4/implementation` branch which has the completed code.
