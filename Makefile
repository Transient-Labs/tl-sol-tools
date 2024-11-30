# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Clean the repo
clean:
	forge clean

# Remove the modules
remove:
	rm -rf dependencies

# Install the modules
install:
	forge soldeer install


# Builds
build:
	forge fmt && forge clean && forge build

# Tests
compiler_test:
	forge test --use 0.8.20
	forge test --use 0.8.21
	forge test --use 0.8.22
	forge test --use 0.8.23
	forge test --use 0.8.24
	forge test --use 0.8.25
	forge test --use 0.8.26
	forge test --use 0.8.27
	forge test --use 0.8.28

quick_test:
	forge test

gas_test:
	forge test --gas-report

fuzz_test:
	forge test --fuzz-runs 10000