// uint256 constant LOCAL_CHAIN_ID = 31_337;
// uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
// uint256 constant OPT_SEPOLIA_CHAIN_ID = 11_155_420;
// uint256 constant ARB_SEPOLIA_CHAIN_ID = 421_614;
// uint256 constant BASE_SEPOLIA_CHAIN_ID = 84_532;

import { ChainProps } from "./types"

export const supportedChains: ChainProps[] = [
  {
    id: 31337,
    name: "Anvil",
    network: "anvil",
    genesisBlock: 0n, 
    erc20s: [], 
    erc721s: [], 
    erc1155s: []
  },
  {
    id: 421614,
    name: "Arbitrum Sepolia",
    network: "arbitrumSepolia",
    blockExplorerUrl: "https://sepolia.arbiscan.io",
    genesisBlock: 111800000n,
    // alternativeBlockNumbers: sepolia
    blockTimeInSeconds: 12, // NB: this is the block time of mainnet because on arbitrum One & Arbitrum sepolia 'block.number' returns the block number of L1 *mainnet* not of the L2! . 
    // ps. when using wagmi's 'getBlock' or 'useBlock' you DO get timestamps based on the L2 blocks. That's just to make thinks simpler :/  
    organisations: [
      "0x78b2efc502847B01e78dcaE37D567494E32D41db", // basicDao 
      "0xF24616397112216b1534624828466D534DF1541D", // alignedDao
      "0x652967D6a917922DF34DD405f76437afD9eC36b8", // govern Your Tax
      // "0x0181A03C24183eA8F6469C88362B0958ACc474Ce" // diversified roles
    ],
    nativeCurrency: {
      name: "Ether", 
      symbol: "ETH", 
      decimals: 18n
    }, 
    erc20s: [
      `0x96B8FDE7522cB57aD19478637033607732412B84`, // Mock 
      `0xe97A5e6C4670DD6fDeA0B5C3E304110eB0e599d9`, // USDC contract
      `0xA977E34e4B8583C6928453CC9572Ae032Cc3200a`, // USDS
      `0xCd5261356706Fd4D8f417F9BffB9dBE575CaE996`, // stEth 
      // what follows or mock token contracts used by the example organisations
      `0x263Bd26E88e6E0fccE33F9cD464664770050973e`, // ERC20VotesMock - basic DAO
      `0xF59e2f5932Aa8a4402285F11184C890a3cbEF0dc`, // ERC20VotesMock - aligned DAO
      `0xBDD1a04A49D1755B76344e19646C34BC92F04d39`, // ERC20TaxedMock - aligned DAO
      `0x9b260d0aD9e89575fA765463ED226c06B56891ce`, // ERC20TaxedMock - govern your tax 
    ], 
    erc721s: [
      `0x535a7772dC1e3B3a5Fe25b7727546110468AbCf3`, // Mock
      `0x1799C697503Ca5B8f71b80b187078CDF06BAB6d7` // Erc721Mock - aligned DAO 
    ], 
    erc1155s: [
      `0x5818B5aeE55696900479eCd410DEC1114c63E430` // Mock 
    ]
  },

]

