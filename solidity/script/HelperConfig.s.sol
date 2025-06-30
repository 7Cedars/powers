// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__UnsupportedChain();

    // @dev we only save the contract addresses of tokens, because any other params (name, symbol, etc) can and should be taken from contract itself.
    struct NetworkConfig {
        uint256 blocksPerHour; // a basic way of establishing time. As long as block times are fairly stable on a chain, this will work.
        address chainlinkFunctionsRouter;
        uint64 chainlinkFunctionsSubscriptionId;
        uint32 chainlinkFunctionsGasLimit;
        bytes32 chainlinkFunctionsDonId;
        string chainlinkFunctionsEncryptedSecretsEndpoint;
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

        function getEthSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300; // new block every 12 seconds

        networkConfig.chainlinkFunctionsRouter = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
        networkConfig.chainlinkFunctionsSubscriptionId = 5819;
        networkConfig.chainlinkFunctionsGasLimit = 300_000;
        networkConfig.chainlinkFunctionsDonId = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
        networkConfig.chainlinkFunctionsEncryptedSecretsEndpoint = "https://01.functions-gateway.testnet.chain.link/";

        return networkConfig;
    }


    function getArbSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300; // new block every 12 seconds

        networkConfig.chainlinkFunctionsRouter = 0x234a5fb5Bd614a7AA2FfAB244D603abFA0Ac5C5C;
        networkConfig.chainlinkFunctionsSubscriptionId = 1;
        networkConfig.chainlinkFunctionsGasLimit = 300_000;
        networkConfig.chainlinkFunctionsDonId = 0x66756e2d617262697472756d2d7365706f6c69612d3100000000000000000000;
        networkConfig.chainlinkFunctionsEncryptedSecretsEndpoint = "https://01.functions-gateway.testnet.chain.link/";

        return networkConfig;
    }


    function getOptSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 1800; // new block every 2 seconds

        networkConfig.chainlinkFunctionsRouter = 0xC17094E3A1348E5C7544D4fF8A36c28f2C6AAE28;
        networkConfig.chainlinkFunctionsSubscriptionId = 256;
        networkConfig.chainlinkFunctionsGasLimit = 300_000;
        networkConfig.chainlinkFunctionsDonId = 0x66756e2d6f7074696d69736d2d7365706f6c69612d3100000000000000000000;
        networkConfig.chainlinkFunctionsEncryptedSecretsEndpoint = "https://01.functions-gateway.testnet.chain.link/";

        return networkConfig;
    }

    function getBaseSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 1800; // new block every 2 seconds

        networkConfig.chainlinkFunctionsRouter = 0xf9B8fc078197181C841c296C876945aaa425B278;
        networkConfig.chainlinkFunctionsSubscriptionId = 1;
        networkConfig.chainlinkFunctionsGasLimit = 300_000;
        networkConfig.chainlinkFunctionsDonId = 0x66756e2d6f7074696d69736d2d7365706f6c69612d3100000000000000000000;
        networkConfig.chainlinkFunctionsEncryptedSecretsEndpoint = "https://01.functions-gateway.testnet.chain.link/";

        return networkConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 3600; // new block per 1 second

        return networkConfig;
    }
}

//////////////////////////////////////////////////////////////////
//                      Acknowledgements                        //
//////////////////////////////////////////////////////////////////

/**
 * - Patrick Collins & Cyfrin: @https://updraft.cyfrin.io/courses/advanced-foundry/account-abstraction
 */
