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
	forge install Hats-Protocol/hats-protocol@v1.0 --no-commit && \
	forge install smartcontractkit/chainlink --no-git --no-commit && \
	forge install smartcontractkit/foundry-chainlink-toolkit --no-git --no-commit

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
ARB_SEPOLIA_DEPLOY_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --chain-id 421614 --etherscan-api-key $(ARBISCAN_API_KEY) --verifier-url https://api-sepolia.arbiscan.io/api --verify -vvvv
OPT_SEPOLIA_DEPLOY_ARGS := --rpc-url $(OPT_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --etherscan-api-key $(OPT_ETHERSCAN_API_KEY) --verify -vvvv

anvilTest :; forge test $(ANVIL_ARGS_0)
arbSepoliaForkedTest :; forge test ${ARB_SEPOLIA_TEST_ARGS}

anvilDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(ANVIL_ARGS_0)
anvilDeployBasic :; forge script script/DeployBasicDao.s.sol:DeployBasicDao $(ANVIL_ARGS_0)
anvilDeployRoles  :; forge script script/DeployDiversifiedRoles.s.sol:DeployDiversifiedRoles $(ANVIL_ARGS_0)

arbSepoliaDeployLaws :; forge script script/DeployLaws.s.sol:DeployLaws $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeployBasic :; forge script script/DeployBasicDao.s.sol:DeployBasicDao $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeployRoles  :; forge script script/DeployDiversifiedRoles.s.sol:DeployDiversifiedRoles $(ARB_SEPOLIA_DEPLOY_ARGS)

arbSepoliaVerifyContract :; forge verify-contract --verifier etherscan --chain-id 421614 --etherscan-api-key $(ARBISCAN_API_KEY) --verifier-url https://api-sepolia.arbiscan.io/api 0x9478aB247F91EAcbcaA1D120d5e35240d294AcA9 src/laws/electoral/NominateMe.sol:NominateMe --watch

# opt Sepolia, sepolia mainnet, etc to follow
optSepoliaDeploy :; forge script script/DeployAlignedDao.s.sol:DeployAlignedDao $(OPT_SEPOLIA_DEPLOY_ARGS)
