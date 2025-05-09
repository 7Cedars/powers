import { createConfig, http, webSocket } from '@wagmi/core'
import { foundry, sepolia, polygonMumbai, baseSepolia, optimismSepolia, arbitrumSepolia, mainnet } from '@wagmi/core/chains'

// [ = preferred ]
export const wagmiConfig = createConfig({
  chains: [arbitrumSepolia, sepolia, foundry], //  foundry,  arbitrumSepolia, sepolia,  baseSepolia, [ optimismSepolia ], polygonMumbai
  transports: {
    [arbitrumSepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_ARB_SEPOLIA_HTTPS), 
    [sepolia.id]: http(process.env.NEXT_PUBLIC_ALCHEMY_SEPOLIA_HTTPS), 
    [foundry.id]: http("http://localhost:8545"),  // 
  },
  ssr: true,
  // storage: createStorage({
  //   storage: cookieStorage
  // })
})