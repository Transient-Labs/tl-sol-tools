# Transient Labs Sol Tools
Inheritable contracts that can be used for a variety of purposes. This is largely inspired by the work done by OpenZeppelin.

## Usage
You should have no trouble inheriting from this library if you install with foundry.

When cloning, you must use either `make remove && make install` or `make update` to install/update the required modules, such as `forge-std` or OpenZeppelin contracts.

We use OpenZeppelin contracts version 5.0.1 in this codebase.

## Testing
You should run the test suites in the Makefile. 

This loops through the following solidity versions:
- 0.8.20
- 0.8.21
- 0.8.22

## Disclaimer
This codebase is provided on an "as is" and "as available" basis.

We do not give any warranties and will not be liable for any loss incurred through any use of this codebase.

## License
This code is copyright Transient Labs, Inc 2023 and is licensed under the MIT license.