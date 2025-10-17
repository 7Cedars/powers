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
	forge install smartcontractkit/chainlink-ccip@contracts-ccip-v1.6.0 --no-commit --no-git && \
	forge install mds1/multicall3 --no-commit --no-git

reset-deps:
	@echo "Resetting dependencies..."
	rm -rf lib/
	forge install foundry-rs/forge-std --no-git && \
	forge install openzeppelin/openzeppelin-contracts@v5.0.2  --no-git && \
	forge install smartcontractkit/chainlink-evm@contracts-v1.4.0  --no-git && \
	forge install smartcontractkit/chainlink-ccip@contracts-ccip-v1.6.0 --no-git && \
	forge install mds1/multicall3 --no-git

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
Multicall3TX := 0xf90f538085174876e800830f42408080b90f00608060405234801561001057600080fd5b50610ee0806100206000396000f3fe6080604052600436106100f35760003560e01c80634d2301cc1161008a578063a8b0574e11610059578063a8b0574e1461025a578063bce38bd714610275578063c3077fa914610288578063ee82ac5e1461029b57600080fd5b80634d2301cc146101ec57806372425d9d1461022157806382ad56cb1461023457806386d516e81461024757600080fd5b80633408e470116100c65780633408e47014610191578063399542e9146101a45780633e64a696146101c657806342cbb15c146101d957600080fd5b80630f28c97d146100f8578063174dea711461011a578063252dba421461013a57806327e86d6e1461015b575b600080fd5b34801561010457600080fd5b50425b6040519081526020015b60405180910390f35b61012d610128366004610a85565b6102ba565b6040516101119190610bbe565b61014d610148366004610a85565b6104ef565b604051610111929190610bd8565b34801561016757600080fd5b50437fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0140610107565b34801561019d57600080fd5b5046610107565b6101b76101b2366004610c60565b610690565b60405161011193929190610cba565b3480156101d257600080fd5b5048610107565b3480156101e557600080fd5b5043610107565b3480156101f857600080fd5b50610107610207366004610ce2565b73ffffffffffffffffffffffffffffffffffffffff163190565b34801561022d57600080fd5b5044610107565b61012d610242366004610a85565b6106ab565b34801561025357600080fd5b5045610107565b34801561026657600080fd5b50604051418152602001610111565b61012d610283366004610c60565b61085a565b6101b7610296366004610a85565b610a1a565b3480156102a757600080fd5b506101076102b6366004610d18565b4090565b60606000828067ffffffffffffffff8111156102d8576102d8610d31565b60405190808252806020026020018201604052801561031e57816020015b6040805180820190915260008152606060208201528152602001906001900390816102f65790505b5092503660005b8281101561047757600085828151811061034157610341610d60565b6020026020010151905087878381811061035d5761035d610d60565b905060200281019061036f9190610d8f565b6040810135958601959093506103886020850185610ce2565b73ffffffffffffffffffffffffffffffffffffffff16816103ac6060870187610dcd565b6040516103ba929190610e32565b60006040518083038185875af1925050503d80600081146103f7576040519150601f19603f3d011682016040523d82523d6000602084013e6103fc565b606091505b50602080850191909152901515808452908501351761046d577f08c379a000000000000000000000000000000000000000000000000000000000600052602060045260176024527f4d756c746963616c6c333a2063616c6c206661696c656400000000000000000060445260846000fd5b5050600101610325565b508234146104e6576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601a60248201527f4d756c746963616c6c333a2076616c7565206d69736d6174636800000000000060448201526064015b60405180910390fd5b50505092915050565b436060828067ffffffffffffffff81111561050c5761050c610d31565b60405190808252806020026020018201604052801561053f57816020015b606081526020019060019003908161052a5790505b5091503660005b8281101561068657600087878381811061056257610562610d60565b90506020028101906105749190610e42565b92506105836020840184610ce2565b73ffffffffffffffffffffffffffffffffffffffff166105a66020850185610dcd565b6040516105b4929190610e32565b6000604051808303816000865af19150503d80600081146105f1576040519150601f19603f3d011682016040523d82523d6000602084013e6105f6565b606091505b5086848151811061060957610609610d60565b602090810291909101015290508061067d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601760248201527f4d756c746963616c6c333a2063616c6c206661696c656400000000000000000060448201526064016104dd565b50600101610546565b5050509250929050565b43804060606106a086868661085a565b905093509350939050565b6060818067ffffffffffffffff8111156106c7576106c7610d31565b60405190808252806020026020018201604052801561070d57816020015b6040805180820190915260008152606060208201528152602001906001900390816106e55790505b5091503660005b828110156104e657600084828151811061073057610730610d60565b6020026020010151905086868381811061074c5761074c610d60565b905060200281019061075e9190610e76565b925061076d6020840184610ce2565b73ffffffffffffffffffffffffffffffffffffffff166107906040850185610dcd565b60405161079e929190610e32565b6000604051808303816000865af19150503d80600081146107db576040519150601f19603f3d011682016040523d82523d6000602084013e6107e0565b606091505b506020808401919091529015158083529084013517610851577f08c379a000000000000000000000000000000000000000000000000000000000600052602060045260176024527f4d756c746963616c6c333a2063616c6c206661696c656400000000000000000060445260646000fd5b50600101610714565b6060818067ffffffffffffffff81111561087657610876610d31565b6040519080825280602002602001820160405280156108bc57816020015b6040805180820190915260008152606060208201528152602001906001900390816108945790505b5091503660005b82811015610a105760008482815181106108df576108df610d60565b602002602001015190508686838181106108fb576108fb610d60565b905060200281019061090d9190610e42565b925061091c6020840184610ce2565b73ffffffffffffffffffffffffffffffffffffffff1661093f6020850185610dcd565b60405161094d929190610e32565b6000604051808303816000865af19150503d806000811461098a576040519150601f19603f3d011682016040523d82523d6000602084013e61098f565b606091505b506020830152151581528715610a07578051610a07576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601760248201527f4d756c746963616c6c333a2063616c6c206661696c656400000000000000000060448201526064016104dd565b506001016108c3565b5050509392505050565b6000806060610a2b60018686610690565b919790965090945092505050565b60008083601f840112610a4b57600080fd5b50813567ffffffffffffffff811115610a6357600080fd5b6020830191508360208260051b8501011115610a7e57600080fd5b9250929050565b60008060208385031215610a9857600080fd5b823567ffffffffffffffff811115610aaf57600080fd5b610abb85828601610a39565b90969095509350505050565b6000815180845260005b81811015610aed57602081850181015186830182015201610ad1565b81811115610aff576000602083870101525b50601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0169290920160200192915050565b600082825180855260208086019550808260051b84010181860160005b84811015610bb1578583037fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe001895281518051151584528401516040858501819052610b9d81860183610ac7565b9a86019a9450505090830190600101610b4f565b5090979650505050505050565b602081526000610bd16020830184610b32565b9392505050565b600060408201848352602060408185015281855180845260608601915060608160051b870101935082870160005b82811015610c52577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa0888703018452610c40868351610ac7565b95509284019290840190600101610c06565b509398975050505050505050565b600080600060408486031215610c7557600080fd5b83358015158114610c8557600080fd5b9250602084013567ffffffffffffffff811115610ca157600080fd5b610cad86828701610a39565b9497909650939450505050565b838152826020820152606060408201526000610cd96060830184610b32565b95945050505050565b600060208284031215610cf457600080fd5b813573ffffffffffffffffffffffffffffffffffffffff81168114610bd157600080fd5b600060208284031215610d2a57600080fd5b5035919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b600082357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff81833603018112610dc357600080fd5b9190910192915050565b60008083357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe1843603018112610e0257600080fd5b83018035915067ffffffffffffffff821115610e1d57600080fd5b602001915036819003821315610a7e57600080fd5b8183823760009101908152919050565b600082357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc1833603018112610dc357600080fd5b600082357fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1833603018112610dc357600080fdfea2646970667358221220bb2b5c71a328032f97c676ae39a1ec2148d3e5d6f73d95e9b17910152d61f16264736f6c634300080c00331ca0edce47092c0f398cebf3ffc267f05c8e7076e3b89445e0fe50f6332273d4569ba01b0b9d000e19b24c5869b0fc3b22b0d6fa47cd63316875cbbd577d76e6fde086
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
anvilDeployMultiCall3 :; cast send --value 1ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x05f32b3cc3888453ff71b01135b34ff8e41263f2 && cast publish $(Multicall3TX) --rpc-url http://localhost:8545


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