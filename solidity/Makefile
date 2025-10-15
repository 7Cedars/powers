# Makefile for Mantle Hackathon Solidity Project
# Standard commands for Foundry-based development

# 
-include .env

.PHONY: help build test test-verbose test-fuzz test-invariant coverage lint clean deploy-anvil deploy-sepolia deploy-mantle verify update-deps install-deps

# Default target
help:
	@echo "Available commands:"
	@echo "  build          - Compile contracts"
	@echo "  test           - Run all tests"
	@echo "  test-verbose   - Run tests with verbose output"
	@echo "  test-fuzz      - Run fuzz tests"
	@echo "  test-invariant - Run invariant tests"
	@echo "  coverage       - Generate coverage report"
	@echo "  lint           - Run linter"
	@echo "  clean          - Clean build artifacts"
	@echo "  deploy-anvil   - Deploy to local Anvil chain"
	@echo "  deploy-sepolia - Deploy to Sepolia testnet"
	@echo "  deploy-mantle  - Deploy to Mantle testnet"
	@echo "  verify         - Verify contracts on Etherscan"
	@echo "  update-deps    - Update dependencies"
	@echo "  install-deps   - Install dependencies"
	@echo "  reset-deps     - Reset dependencies"

# Build commands
build:
	@echo "Building contracts..."
	forge build

build-verbose:
	@echo "Building contracts with verbose output..."
	forge build -vvv

# Test commands
test:
	@echo "Running tests..."
	forge test

test-verbose:
	@echo "Running tests with verbose output..."
	forge test -vvv

test-fuzz:
	@echo "Running fuzz tests..."
	forge test --match-test testFuzz_ -vvv

test-invariant:
	@echo "Running invariant tests..."
	forge test --match-test invariant_ -vvv

test-specific:
	@echo "Running specific test: $(TEST)"
	forge test --match-test $(TEST) -vvv

test-contract:
	@echo "Running tests for contract: $(CONTRACT)"
	forge test --match-contract $(CONTRACT) -vvv

# Coverage
coverage:
	@echo "Generating coverage report..."
	forge coverage --report lcov
	@echo "Coverage report generated in lcov.info"

coverage-html:
	@echo "Generating HTML coverage report..."
	forge coverage --report html
	@echo "HTML coverage report generated in coverage/"

# Linting
lint:
	@echo "Running linter..."
	forge lint

lint-high:
	@echo "Running linter with high severity only..."
	forge lint --severity high

# Clean
clean:
	@echo "Cleaning build artifacts..."
	forge clean
	rm -rf out/
	rm -rf cache/

# Anvil commands
anvil:
	@echo "Starting Anvil local chain..."
	anvil

# Deployment commands
deploy-anvil:
	@echo "Deploying to local Anvil chain..."
	forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast -vvvv

deploy-sepolia:
	@echo "Deploying to Sepolia testnet..."
	forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify -vvvv --interactives 1

deploy-mantle:
	@echo "Deploying to Mantle testnet..."
	forge script script/Deploy.s.sol --rpc-url mantle_testnet --broadcast --verify -vvvv --interactives 1

deploy-resume:
	@echo "Resuming deployment..."
	forge script script/Deploy.s.sol --rpc-url $(RPC_URL) --resume

# Verification
verify:
	@echo "Verifying contracts..."
	forge verify-contract $(CONTRACT_ADDRESS) $(CONTRACT_NAME) --chain-id $(CHAIN_ID) --etherscan-api-key $(ETHERSCAN_API_KEY)

# Dependency management
update-deps:
	@echo "Updating dependencies..."
	forge update

install-deps:
	@echo "Installing dependencies..."
	forge install foundry-rs/forge-std --no-commit --no-git && \
	forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit --no-git && \
	forge install smartcontractkit/chainlink-evm@contracts-v1.4.0 --no-commit --no-git && \
	forge install smartcontractkit/chainlink-ccip@contracts-ccip-v1.6.0 --no-commit --no-git 

reset-deps:
	@echo "Resetting dependencies..."
	rm -rf lib/
	forge install foundry-rs/forge-std --no-git && \
	forge install openzeppelin/openzeppelin-contracts@v5.0.2  --no-git && \
	forge install smartcontractkit/chainlink-evm@contracts-v1.4.0  --no-git && \
	forge install smartcontractkit/chainlink-ccip@contracts-ccip-v1.6.0 --no-git 

# Documentation
doc:
	@echo "Generating documentation..."
	forge doc

doc-serve:
	@echo "Serving documentation..."
	forge doc --serve

# Gas reporting
gas-report:
	@echo "Generating gas report..."
	forge test --gas-report

# Snapshot
snapshot:
	@echo "Creating gas snapshot..."
	forge snapshot

# Size analysis
size:
	@echo "Analyzing contract sizes..."
	forge build --sizes

# Security analysis
security:
	@echo "Running security analysis..."
	forge build
	forge inspect $(CONTRACT) methods
	forge inspect $(CONTRACT) abi

# Environment setup
setup-env:
	@echo "Setting up environment..."
	@if [ ! -f .env ]; then \
		echo "Creating .env file from template..."; \
		cp .env.example .env; \
		echo "Please update .env with your configuration"; \
	else \
		echo ".env file already exists"; \
	fi

# Quick development workflow
dev: clean build test lint
	@echo "Development workflow completed"

# Full CI/CD workflow
ci: clean build test-verbose coverage lint
	@echo "CI/CD workflow completed"

# Helpers for specific networks
deploy-sepolia-dry:
	@echo "Simulating deployment to Sepolia..."
	forge script script/Deploy.s.sol --rpc-url sepolia -vvvv

deploy-mantle-dry:
	@echo "Simulating deployment to Mantle..."
	forge script script/Deploy.s.sol --rpc-url mantle_testnet -vvvv

# Contract interaction helpers
call:
	@echo "Making contract call..."
	cast call $(CONTRACT_ADDRESS) $(FUNCTION_SIG) $(ARGS) --rpc-url $(RPC_URL)

send:
	@echo "Sending transaction..."
	cast send $(CONTRACT_ADDRESS) $(FUNCTION_SIG) $(ARGS) --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

# Debug helpers
debug-test:
	@echo "Debugging test: $(TEST)"
	forge test --match-test $(TEST) -vvvv

trace:
	@echo "Tracing transaction: $(TX_HASH)"
	cast run $(TX_HASH) --rpc-url $(RPC_URL) -vvvv

# Network info
block-info:
	@echo "Getting block information..."
	cast block latest --rpc-url $(RPC_URL)

gas-price:
	@echo "Getting current gas price..."
	cast gas-price --rpc-url $(RPC_URL)

# Contract verification helpers
flatten:
	@echo "Flattening contract: $(CONTRACT)"
	forge flatten src/$(CONTRACT).sol

# Advanced testing
test-fork:
	@echo "Running fork tests..."
	forge test --match-test testFork_ -vvv

test-gas:
	@echo "Running gas tests..."
	forge test --gas-report --match-test testGas_

# Development shortcuts
watch:
	@echo "Watching for changes and running tests..."
	while inotifywait -r -e modify src/ test/; do \
		forge test; \
	done

# Project initialization
init-project:
	@echo "Initializing project structure..."
	mkdir -p src/interfaces
	mkdir -p src/libraries
	mkdir -p src/abstracts
	mkdir -p test/unit
	mkdir -p test/integration
	mkdir -p test/fuzz
	mkdir -p test/invariant
	mkdir -p test/fork
	mkdir -p test/utils
	mkdir -p script
	mkdir -p docs
	@echo "Project structure created"

# Show project info
info:
	@echo "Project Information:"
	@echo "===================="
	@echo "Foundry version: $(shell forge --version)"
	@echo "Solidity version: $(shell grep 'solc_version' foundry.toml | cut -d'=' -f2 | tr -d ' "')"
	@echo "Dependencies:"
	@ls lib/
	@echo ""
	@echo "Available contracts:"
	@find src/ -name "*.sol" -type f 2>/dev/null || echo "No contracts found in src/"
	@echo ""
	@echo "Available tests:"
	@find test/ -name "*.t.sol" -type f 2>/dev/null || echo "No tests found in test/" 



###############################
# 		Deploy Commands  				# 
###############################
ANVIL_ARGS_0 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_0) --broadcast --ffi -vv
ARB_SEPOLIA_TEST_ARGS := --fork-url $(ARB_SEPOLIA_RPC_URL)

SEPOLIA_DEPLOY_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verifier etherscan --chain 11155111 --verify -vvvv
ARB_SEPOLIA_DEPLOY_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verifier etherscan --chain 421614 --verify -vvvv
OPT_SEPOLIA_DEPLOY_ARGS := --rpc-url $(OPT_SEPOLIA_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verifier etherscan --chain 11155420 --verify -vvvv
OPT_DEPLOY_ARGS := --rpc-url $(OPT_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(OPTISCAN_API_KEY) --verifier etherscan --chain 10 --verify -vvvv
MANTLE_SEPOLIA_DEPLOY_ARGS := --rpc-url $(MANTLE_SEPOLIA_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verifier etherscan --chain 5003 --verify -vvvv

anvilTest :; forge test $(ANVIL_ARGS_0)
arbSepoliaForkedTest :; forge test ${ARB_SEPOLIA_TEST_ARGS}

# anvil local 
anvilDeployTest :; forge script script/DeployTestOrgs.s.sol:DeployTestOrgs $(ANVIL_ARGS_0)
anvilInitialise :; forge script script/InitialisePowers.s.sol:InitialisePowers $(ANVIL_ARGS_0)
anvilDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(ANVIL_ARGS_0)

# # Ethereum sepolia 
# sepoliaDeployVanillaPowers :; forge script script/DeployVanillaPowers.sol:DeployVanillaPowers $(SEPOLIA_DEPLOY_ARGS)
# sepoliaDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(SEPOLIA_DEPLOY_ARGS) && \
# 	forge script script/DeployLaws.s.sol:DeployLaws $(SEPOLIA_DEPLOY_ARGS) 
# sepoliaDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(SEPOLIA_DEPLOY_ARGS)
# sepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(SEPOLIA_DEPLOY_ARGS)
# sepoliaDeploy101 :; forge script script/DeployPowers101.s.sol:DeployPowers101 $(SEPOLIA_DEPLOY_ARGS)
# sepoliaDeploySeparatedPowers :; forge script script/DeploySeparatedPowers.s.sol:DeploySeparatedPowers $(SEPOLIA_DEPLOY_ARGS)
# sepoliaDeployBeyondPowers :; forge script script/DeployBeyondPowers2.s.sol:DeployBeyondPowers2 $(SEPOLIA_DEPLOY_ARGS)

# # Arbitrum sepolia
# arbSepoliaDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(ARB_SEPOLIA_DEPLOY_ARGS) && \
# 	forge script script/DeployLaws.s.sol:DeployLaws $(ARB_SEPOLIA_DEPLOY_ARGS) 
# arbSepoliaDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(ARB_SEPOLIA_DEPLOY_ARGS)
# arbSepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(ARB_SEPOLIA_DEPLOY_ARGS)
# arbSepoliaDeploy101 :; forge script script/DeployPowers101.s.sol:DeployPowers101 $(ARB_SEPOLIA_DEPLOY_ARGS)
# arbSepoliaDeploySeparatedPowers :; forge script script/DeploySeparatedPowers.s.sol:DeploySeparatedPowers $(ARB_SEPOLIA_DEPLOY_ARGS)
# arbSepoliaDeployGovernedUpgrades :; forge script script/DeployGovernedUpgrades.s.sol:DeployGovernedUpgrades $(ARB_SEPOLIA_DEPLOY_ARGS)
# arbSepoliaDeployManagedGrants :; forge script script/DeployManagedGrants.s.sol:DeployManagedGrants $(ARB_SEPOLIA_DEPLOY_ARGS)
# arbSepoliaDeployBeyondPowers :; forge script script/DeployBeyondPowers.s.sol:DeployBeyondPowers $(ARB_SEPOLIA_DEPLOY_ARGS)

# # Optimism sepolia
# optSepoliaDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(OPT_SEPOLIA_DEPLOY_ARGS) && \
# 	forge script script/DeployLaws.s.sol:DeployLaws $(OPT_SEPOLIA_DEPLOY_ARGS) 
# optSepoliaDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(OPT_SEPOLIA_DEPLOY_ARGS)
# optSepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(OPT_SEPOLIA_DEPLOY_ARGS)
# optSepoliaDeploy101 :; forge script script/DeployPowers101.s.sol:DeployPowers101 $(OPT_SEPOLIA_DEPLOY_ARGS)
# optSepoliaDeploySeparatedPowers :; forge script script/DeploySeparatedPowers.s.sol:DeploySeparatedPowers $(OPT_SEPOLIA_DEPLOY_ARGS)
# optSepoliaDeployGovernedUpgrades :; forge script script/DeployGovernedUpgrades.s.sol:DeployGovernedUpgrades $(OPT_SEPOLIA_DEPLOY_ARGS)
# optSepoliaDeployManagedGrants :; forge script script/DeployManagedGrants.s.sol:DeployManagedGrants $(OPT_SEPOLIA_DEPLOY_ARGS)
# optSepoliaDeployBeyondPowers :; forge script script/DeployBeyondPowers.s.sol:DeployBeyondPowers $(OPT_SEPOLIA_DEPLOY_ARGS)

# # Mantle sepolia 
# mantleSepoliaDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(MANTLE_SEPOLIA_DEPLOY_ARGS) && \
# 	forge script script/DeployLaws.s.sol:DeployLaws $(MANTLE_SEPOLIA_DEPLOY_ARGS) 
# mantleSepoliaDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(MANTLE_SEPOLIA_DEPLOY_ARGS)
# mantleSepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(MANTLE_SEPOLIA_DEPLOY_ARGS)
# mantleSepoliaDeployVanillaPowers :; forge script script/DeployVanillaPowers.sol:DeployVanillaPowers $(MANTLE_SEPOLIA_DEPLOY_ARGS)


# optSepoliaVerifyContract :; forge verify-contract --etherscan-api-key $(ETHERSCAN_API_KEY) --chain 11155420 --verifier etherscan 0x53CB3281823Ea08439Cf9Ac9F403c08FBF94d490 test/mocks/Erc20VotesMock.sol:Erc20VotesMock --watch
# sepoliaVerifyContract :; forge verify-contract --etherscan-api-key $(ETHERSCAN_API_KEY) --chain 11155111 --verifier etherscan 0x05c0379565ef0ebb1bD21C0Ab463ca5CE5211D3A src/Powers.sol:Powers --watch
# mantleSepoliaVerifyContract :; forge verify-contract --etherscan-api-key $(ETHERSCAN_API_KEY) --chain 5003 --verifier etherscan 0x4cba41c3d34a6177659126517b9806acefa0f83c --compiler-version 0.8.26 src/laws/electoral/DelegateSelect.sol:DelegateSelect --watch