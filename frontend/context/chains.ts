// uint256 constant LOCAL_CHAIN_ID = 31_337;
// uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
// uint256 constant OPT_SEPOLIA_CHAIN_ID = 11_155_420;
// uint256 constant ARB_SEPOLIA_CHAIN_ID = 421_614;
// uint256 constant BASE_SEPOLIA_CHAIN_ID = 84_532;

import { ChainProps } from "./types"

export const supportedChains: ChainProps[] = [
  {
    id: 31337,
    name: "Foundry",
    network: "foundry",
    genesisBlock: 0n,
    blockTimeInSeconds: 1,
    nativeCurrency: {
      name: "Ether", 
      symbol: "ETH", 
      decimals: 18n
    }
  },
  {
    id: 11155111,
    name: "Ethereum Sepolia",
    network: "sepolia",
    blockExplorerUrl: "https://sepolia.etherscan.io/",
    genesisBlock: 111800000n,
    blockTimeInSeconds: 12,
    nativeCurrency: {
      name: "Ether", 
      symbol: "ETH", 
      decimals: 18n
    }
  },
  {
    id: 421614,
    name: "Arbitrum Sepolia",
    network: "arbitrumSepolia",
    blockExplorerUrl: "https://sepolia.arbiscan.io",
    genesisBlock: 111800000n,
    alternativeBlockNumbers: 11155111, 
    blockTimeInSeconds: 12, // NB: this is the block time of mainnet because on arbitrum One & Arbitrum sepolia 'block.number' returns the block number of L1 *mainnet* not of the L2! . 
    nativeCurrency: {
      name: "Ether", 
      symbol: "ETH", 
      decimals: 18n
    }
  }
]

