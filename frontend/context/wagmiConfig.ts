import { createConfig, http, webSocket } from '@wagmi/core'
import { injected, coinbaseWallet } from '@wagmi/connectors'
import { foundry, sepolia, polygonMumbai, baseSepolia, arbitrumSepolia, mainnet, xLayerTestnet, mantleSepoliaTestnet } from '@wagmi/core/chains' 
import { defineChain } from 'viem'

const sourceId = 11_155_111 // sepolia

export const optimismSepolia = defineChain({
  id: 11155420,
  name: 'OP Sepolia',
  nativeCurrency: { name: 'Sepolia Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: {
      http: ['https://sepolia.optimism.io'],
    },
  },
  blockExplorers: {
    default: {
      name: 'Blockscout',
      url: 'https://sepolia-optimism.etherscan.io/',
      apiUrl: 'https://sepolia-optimism.etherscan.io/api',
    },
  },
  contracts: {
    disputeGameFactory: {
      [sourceId]: {
        address: '0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1',
      },
    },
    l2OutputOracle: {
      [sourceId]: {
        address: '0x90E9c4f8a994a250F6aEfd61CAFb4F2e895D458F',
      },
    },
    multicall3: {
      address: '0xca11bde05977b3631167028862be2a173976ca11',
      blockCreated: 1620204,
    },
    portal: {
      [sourceId]: {
        address: '0x16Fc5058F25648194471939df75CF27A2fdC48BC',
      },
    },
    l1StandardBridge: {
      [sourceId]: {
        address: '0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1',
      },
    },
  },
  testnet: true,
  sourceId,
})

// [ = preferred ]
const isLocalhost = typeof window !== 'undefined' && window.location.hostname === 'localhost';

export const wagmiConfig = createConfig({
  chains: [
    arbitrumSepolia, 
    sepolia, 
    optimismSepolia,
    mantleSepoliaTestnet,
    ...(isLocalhost ? [foundry] : [])
  ],
  // batch: { multicall: true }, 
  connectors: [injected(), coinbaseWallet()],
  transports: {
    [arbitrumSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_ARB_SEPOLIA_HTTPS), 
    [sepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_SEPOLIA_HTTPS), 
    [optimismSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_OPT_SEPOLIA_HTTPS),
    [mantleSepoliaTestnet.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_MANTLE_SEPOLIA_HTTPS),
    // [baseSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_BASE_SEPOLIA_HTTPS),
    [foundry.id]: http("http://localhost:8545"),   
  },
  ssr: true,
  // storage: createStorage({
  //   storage: cookieStorage
  // })
})