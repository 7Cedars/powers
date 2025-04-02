// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__UnsupportedChain();

    // @dev we only save the contract addresses of tokens, because any other params (name, symbol, etc) can and should be taken from contract itself.
    struct NetworkConfig {
        uint256 blocksPerHour; // a basic way of establishing time. As long as block times are fairly stable on a chain, this will work.
    }

    uint256 constant LOCAL_CHAIN_ID = 31_337;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
    uint256 constant OPT_SEPOLIA_CHAIN_ID = 11_155_420;
    uint256 constant ARB_SEPOLIA_CHAIN_ID = 421_614;
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84_532;

    NetworkConfig public networkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilEthConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ARB_SEPOLIA_CHAIN_ID] = getArbSepoliaConfig();
        networkConfigs[OPT_SEPOLIA_CHAIN_ID] = getOptSepoliaConfig();
        networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].blocksPerHour != 0) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__UnsupportedChain();
        }
    }

    function getArbSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getEthSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getOptSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getBaseSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 3600;

        return networkConfig;
    }
}

//////////////////////////////////////////////////////////////////
//                      Acknowledgements                        //
//////////////////////////////////////////////////////////////////

/**
 * - Patrick Collins & Cyfrin: @https://updraft.cyfrin.io/courses/advanced-foundry/account-abstraction
 */
