# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Clean the repo
clean:
	forge clean

# Remove the modules
remove:
	rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules

# Install the modules
install:
	forge install foundry-rs/forge-std --no-commit
	forge install OpenZeppelin/openzeppelin-contracts@v5.0.1 --no-commit
	forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.0.1 --no-commit
	forge install manifoldxyz/royalty-registry-solidity --no-commit

# Updatee the modules
update: remove install

# Builds
build:
	forge fmt && forge clean && forge build

# Tests
compiler_test:
	forge test --use 0.8.20
	forge test --use 0.8.21
	forge test --use 0.8.22
	forge test --use 0.8.23

quick_test:
	forge test --fuzz-runs 512

gas_test:
	forge test --gas-report

fuzz_test:
	forge test --fuzz-runs 10000