import { createConfig, http, webSocket } from '@wagmi/core'
import { foundry, sepolia, polygonMumbai, baseSepolia, optimismSepolia, arbitrumSepolia, mainnet } from '@wagmi/core/chains'

// [ = preferred ]
export const wagmiConfig = createConfig({
  chains: [arbitrumSepolia, sepolia], //  foundry,  arbitrumSepolia, sepolia,  baseSepolia, [ optimismSepolia ], polygonMumbai
  transports: {
    // [arbitrumSepolia.id]: http(`https://arb-sepolia.g.alchemy.com/v2/${process.env.NEXT_PUBLIC_ALCHEMY_ARB_SEP_API_KEY}`), 
    [arbitrumSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_ARB_SEPOLIA_HTTPS), 
    [sepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_SEPOLIA_HTTPS), 
    // [baseSepolia.id]: http(), 
    // [optimismSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_OPT_SEPOLIA_HTTPS),
    [foundry.id]: http("http://localhost:8545"),  // 
    // [polygonMumbai.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_POLYGON_MUMBAI_API_RPC)
  },
  ssr: true,
  // storage: createStorage({
  //   storage: cookieStorage
  // })
})