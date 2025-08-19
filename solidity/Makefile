# £ack this file was originally copied from https://github.com/Cyfrin/foundry-erc20-f23/blob/main/Makefile
-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

all: clean remove install update build test

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules 
#&& git add . 
#&& git commit -m "modules"

# Install modules
install :; forge install foundry-rs/forge-std@v1.9.1 --no-commit && \
	forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit && \
	forge install smartcontractkit/chainlink-evm --no-git --no-commit && \
	forge install smartcontractkit/foundry-chainlink-toolkit --no-git --no-commit
# forge install Hats-Protocol/hats-protocol@v1.0 --no-commit

# Update Dependencies
update :; forge update

# Build
build :; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil --steps-tracing --block-time 1

###############################
# 		Deploy Commands  				# 
###############################
ANVIL_ARGS_0 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_0) --broadcast
ARB_SEPOLIA_TEST_ARGS := --fork-url $(ARB_SEPOLIA_RPC_URL)

SEPOLIA_DEPLOY_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verifier etherscan --chain 11155111 --verify -vvvv
ARB_SEPOLIA_DEPLOY_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(ARBISCAN_API_KEY) --verifier etherscan --chain 421614 --verify -vvvv
OPT_SEPOLIA_DEPLOY_ARGS := --rpc-url $(OPT_SEPOLIA_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(OPTISCAN_API_KEY) --verifier etherscan --chain 11155420 --verify -vvvv
OPT_DEPLOY_ARGS := --rpc-url $(OPT_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(OPTISCAN_API_KEY) --verifier etherscan --chain 10 --verify -vvvv
MANTLE_SEPOLIA_DEPLOY_ARGS := --rpc-url $(MANTLE_SEPOLIA_RPC_URL) --account dev_3 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verifier etherscan --chain 5003 --verify -vvvv

anvilTest :; forge test $(ANVIL_ARGS_0)
arbSepoliaForkedTest :; forge test ${ARB_SEPOLIA_TEST_ARGS}

# anvil local 
anvilDeployVanillaPowers :; forge script script/DeployVanillaPowers.sol:DeployVanillaPowers $(ANVIL_ARGS_0)
anvilDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(ANVIL_ARGS_0) && \
	forge script script/DeployLaws.s.sol:DeployLaws $(ANVIL_ARGS_0) 
anvilDeploy101 :; forge script script/DeployPowers101.s.sol:DeployPowers101 $(ANVIL_ARGS_0)
anvilDeploySeparatedPowers :; forge script script/DeploySeparatedPowers.s.sol:DeploySeparatedPowers $(ANVIL_ARGS_0)
anvilDeployGovernedUpgrades :; forge script script/DeployGovernedUpgrades.s.sol:DeployGovernedUpgrades $(ANVIL_ARGS_0)
anvilDeployManagedGrants :; forge script script/DeployManagedGrants.s.sol:DeployManagedGrants $(ANVIL_ARGS_0)

# Ethereum sepolia 
sepoliaDeployVanillaPowers :; forge script script/DeployVanillaPowers.sol:DeployVanillaPowers $(SEPOLIA_DEPLOY_ARGS)
sepoliaDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(SEPOLIA_DEPLOY_ARGS) && \
	forge script script/DeployLaws.s.sol:DeployLaws $(SEPOLIA_DEPLOY_ARGS) 
sepoliaDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(SEPOLIA_DEPLOY_ARGS)
sepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(SEPOLIA_DEPLOY_ARGS)
sepoliaDeploy101 :; forge script script/DeployPowers101.s.sol:DeployPowers101 $(SEPOLIA_DEPLOY_ARGS)
sepoliaDeploySeparatedPowers :; forge script script/DeploySeparatedPowers.s.sol:DeploySeparatedPowers $(SEPOLIA_DEPLOY_ARGS)
sepoliaDeployBeyondPowers :; forge script script/DeployBeyondPowers2.s.sol:DeployBeyondPowers2 $(SEPOLIA_DEPLOY_ARGS)

# Arbitrum sepolia
arbSepoliaDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(ARB_SEPOLIA_DEPLOY_ARGS) && \
	forge script script/DeployLaws.s.sol:DeployLaws $(ARB_SEPOLIA_DEPLOY_ARGS) 
arbSepoliaDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeploy101 :; forge script script/DeployPowers101.s.sol:DeployPowers101 $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeploySeparatedPowers :; forge script script/DeploySeparatedPowers.s.sol:DeploySeparatedPowers $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeployGovernedUpgrades :; forge script script/DeployGovernedUpgrades.s.sol:DeployGovernedUpgrades $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeployManagedGrants :; forge script script/DeployManagedGrants.s.sol:DeployManagedGrants $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeployBeyondPowers :; forge script script/DeployBeyondPowers.s.sol:DeployBeyondPowers $(ARB_SEPOLIA_DEPLOY_ARGS)

# Optimism sepolia
optSepoliaDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(OPT_SEPOLIA_DEPLOY_ARGS) && \
	forge script script/DeployLaws.s.sol:DeployLaws $(OPT_SEPOLIA_DEPLOY_ARGS) 
optSepoliaDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(OPT_SEPOLIA_DEPLOY_ARGS)
optSepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(OPT_SEPOLIA_DEPLOY_ARGS)
optSepoliaDeploy101 :; forge script script/DeployPowers101.s.sol:DeployPowers101 $(OPT_SEPOLIA_DEPLOY_ARGS)
optSepoliaDeploySeparatedPowers :; forge script script/DeploySeparatedPowers.s.sol:DeploySeparatedPowers $(OPT_SEPOLIA_DEPLOY_ARGS)
optSepoliaDeployGovernedUpgrades :; forge script script/DeployGovernedUpgrades.s.sol:DeployGovernedUpgrades $(OPT_SEPOLIA_DEPLOY_ARGS)
optSepoliaDeployManagedGrants :; forge script script/DeployManagedGrants.s.sol:DeployManagedGrants $(OPT_SEPOLIA_DEPLOY_ARGS)
optSepoliaDeployBeyondPowers :; forge script script/DeployBeyondPowers.s.sol:DeployBeyondPowers $(OPT_SEPOLIA_DEPLOY_ARGS)

# Mantle sepolia 
mantleSepoliaDeployAll :; forge script script/DeployMocks.s.sol:DeployMocks $(MANTLE_SEPOLIA_DEPLOY_ARGS) && \
	forge script script/DeployLaws.s.sol:DeployLaws $(MANTLE_SEPOLIA_DEPLOY_ARGS) 
mantleSepoliaDeployMocks :; forge script script/DeployMocks.s.sol:DeployMocks $(MANTLE_SEPOLIA_DEPLOY_ARGS)
mantleSepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(MANTLE_SEPOLIA_DEPLOY_ARGS)
mantleSepoliaDeployVanillaPowers :; forge script script/DeployVanillaPowers.sol:DeployVanillaPowers $(MANTLE_SEPOLIA_DEPLOY_ARGS)

sepoliaVerifyContract :; forge verify-contract --etherscan-api-key $(ETHERSCAN_API_KEY) --chain 11155111 --verifier etherscan 0x05c0379565ef0ebb1bD21C0Ab463ca5CE5211D3A src/Powers.sol:Powers --watch
mantleSepoliaVerifyContract :; forge verify-contract --etherscan-api-key $(ETHERSCAN_API_KEY) --chain 5003 --verifier etherscan 0x4cba41c3d34a6177659126517b9806acefa0f83c --compiler-version 0.8.26 src/laws/electoral/DelegateSelect.sol:DelegateSelect --watch